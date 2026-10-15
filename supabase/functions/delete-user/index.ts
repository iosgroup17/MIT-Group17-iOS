// supabase/functions/delete-user/index.ts
//
// Deletes a user entirely from Supabase Auth (auth.users) and revokes their
// Apple Sign-In refresh token if they authenticated via Apple.
//
// ALL Apple credentials are read from Supabase environment secrets — nothing
// is hard-coded. Set them once with:
//
//   supabase secrets set \
//     APPLE_TEAM_ID=FS8622R56Y \
//     APPLE_KEY_ID=4KSCW7Z3LA \
//     APPLE_PRIVATE_KEY="$(cat AuthKey_4KSCW7Z3LA.p8)"
//
// The iOS client sends:
//   { "apple_authorization_code": "<one-time code from ASAuthorizationAppleIDCredential>" }
//
// Required env secrets:
//   SUPABASE_URL              – auto-injected by Supabase
//   SUPABASE_SERVICE_ROLE_KEY – auto-injected by Supabase
//   APPLE_TEAM_ID             – FS8622R56Y
//   APPLE_KEY_ID              – 4KSCW7Z3LA
//   APPLE_PRIVATE_KEY         – full PEM contents of the .p8 file

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// Helper: build a signed JWT (client_secret) for Apple's token endpoint.
// Apple requires ES256 JWTs signed with the .p8 private key.
// ---------------------------------------------------------------------------
async function buildAppleClientSecret(): Promise<string> {
  const teamId        = Deno.env.get("APPLE_TEAM_ID");
  const keyId         = Deno.env.get("APPLE_KEY_ID");
  const privateKeyPem = Deno.env.get("APPLE_PRIVATE_KEY");
  const clientId      = "com.Team17.HandleHQ"; // Bundle ID — not a secret

  if (!teamId || !keyId || !privateKeyPem) {
    throw new Error(
      "Missing Apple secret env vars: APPLE_TEAM_ID, APPLE_KEY_ID, or APPLE_PRIVATE_KEY"
    );
  }

  const now = Math.floor(Date.now() / 1000);

  const header  = { alg: "ES256", kid: keyId };
  const payload = {
    iss: teamId,
    iat: now,
    exp: now + 300, // 5-minute window is enough for one revocation call
    aud: "https://appleid.apple.com",
    sub: clientId,
  };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");

  const signingInput = `${encode(header)}.${encode(payload)}`;

  // Strip PEM armour and decode raw PKCS#8 DER bytes
  const pemBody = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");

  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  const signatureB64 = btoa(
    String.fromCharCode(...new Uint8Array(signature))
  )
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  return `${signingInput}.${signatureB64}`;
}

// ---------------------------------------------------------------------------
// Helper: exchange one-time authorizationCode for a refresh_token, then
// immediately revoke it — satisfying Apple's account-deletion requirement.
// ---------------------------------------------------------------------------
async function revokeAppleToken(authorizationCode: string): Promise<void> {
  const clientSecret = await buildAppleClientSecret();
  const clientId     = "com.Team17.HandleHQ";

  // Step 1: exchange code → refresh_token
  const tokenRes = await fetch("https://appleid.apple.com/auth/token", {
    method:  "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:    new URLSearchParams({
      client_id:     clientId,
      client_secret: clientSecret,
      code:          authorizationCode,
      grant_type:    "authorization_code",
    }),
  });

  if (!tokenRes.ok) {
    const err = await tokenRes.text();
    // invalid_grant = code already used / expired; treat as non-fatal
    console.warn("Apple /auth/token warning:", err);
    return;
  }

  const tokenData    = await tokenRes.json();
  const refreshToken = tokenData.refresh_token as string | undefined;

  if (!refreshToken) {
    console.warn("No refresh_token returned by Apple — skipping revocation.");
    return;
  }

  // Step 2: revoke the refresh_token
  const revokeRes = await fetch("https://appleid.apple.com/auth/revoke", {
    method:  "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:    new URLSearchParams({
      client_id:       clientId,
      client_secret:   clientSecret,
      token:           refreshToken,
      token_type_hint: "refresh_token",
    }),
  });

  if (!revokeRes.ok) {
    console.warn("Apple /auth/revoke warning:", await revokeRes.text());
  } else {
    console.log("Apple refresh token successfully revoked.");
  }
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------
serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Admin client — bypasses RLS so it can call auth.admin.deleteUser
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  // Authenticate the caller via their Supabase JWT — only self-deletion allowed
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const jwt = authHeader.replace("Bearer ", "");
  const { data: { user }, error: userError } =
    await supabaseAdmin.auth.getUser(jwt);

  if (userError || !user) {
    return new Response(JSON.stringify({ error: "Invalid session" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Parse optional Apple authorization code
  let appleAuthorizationCode: string | undefined;
  try {
    const body = await req.json();
    appleAuthorizationCode = body?.apple_authorization_code;
  } catch {
    // No body or non-JSON body — fine for Google / email users
  }

  // Step A: Revoke Apple token (Apple Sign-In users only)
  if (appleAuthorizationCode) {
    try {
      await revokeAppleToken(appleAuthorizationCode);
    } catch (e) {
      // Log but don't block deletion — leaving user stuck is worse than skipping revocation
      console.error("Apple revocation error (non-fatal):", e);
    }
  }

  // Step B: Hard-delete from auth.users (cascades to public.profiles via FK)
  const { error: deleteError } =
    await supabaseAdmin.auth.admin.deleteUser(user.id);

  if (deleteError) {
    console.error("auth.admin.deleteUser error:", deleteError);
    return new Response(
      JSON.stringify({ error: "Failed to delete account." }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  console.log(`User ${user.id} successfully deleted.`);
  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
