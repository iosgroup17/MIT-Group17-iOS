import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { handle, user_id, p_variable = 0 } = await req.json()
    console.log(`\n=== 🐦 TWITTER SCRAPE V7 (FIX): ${handle} ===`)

    const RAPID_KEY = Deno.env.get('RAPIDAPI_KEY')
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // 1. FETCH STATE
    const { data: currentData } = await supabase.from('user_analytics').select('*').eq('user_id', user_id).single()

    // 2. RESOLVE ID
    const cleanHandle = handle.replace('@', '').trim()
    const profileResp = await fetch(`https://twitter241.p.rapidapi.com/user?username=${cleanHandle}`, {
      headers: { 'x-rapidapi-key': RAPID_KEY!, 'x-rapidapi-host': 'twitter241.p.rapidapi.com' }
    })
    const profileData = await profileResp.json()
    const twitterID = profileData.result?.data?.user?.result?.rest_id || 
                      profileData.user?.result?.rest_id || 
                      profileData.data?.user?.result?.rest_id

    if (!twitterID) throw new Error("Twitter User Not Found")

    // 3. GET TWEETS
    const tweetsResp = await fetch(`https://twitter241.p.rapidapi.com/user-tweets?user=${twitterID}&count=20`, {
      headers: { 'x-rapidapi-key': RAPID_KEY!, 'x-rapidapi-host': 'twitter241.p.rapidapi.com' }
    })
    const tweetsData = await tweetsResp.json()
    
    const instructions = tweetsData.result?.timeline?.instructions || 
                         tweetsData.data?.user?.result?.timeline?.timeline?.instructions || []
    let entries: any[] = []
    instructions.forEach((instr: any) => {
        if (instr.type === "TimelineAddEntries" && instr.entries) entries = entries.concat(instr.entries)
        if (instr.type === "TimelinePinEntry" && instr.entry) entries.push(instr.entry)
    })

    // 4. ANALYZE
    const now = new Date()
    const startOfWeek = new Date(now)
    startOfWeek.setDate(now.getDate() - ((now.getDay() + 6) % 7))
    startOfWeek.setHours(0,0,0,0)

    let postsThisWeek = 0
    let totalRawEngagement = 0
    let validPostCount = 0
    const dailyMap: Record<string, number> = {}

    entries.forEach((entry: any) => {
        if (entry.entryId?.startsWith("promoted") || entry.entryId?.startsWith("who-to-follow")) return
        const legacy = entry.content?.itemContent?.tweet_results?.result?.legacy
        if (legacy && legacy.created_at) {
            const eng = (legacy.favorite_count || 0) + (legacy.retweet_count || 0) + (legacy.reply_count || 0)
            
            const postDate = new Date(legacy.created_at)
            if (postDate >= startOfWeek) {
                postsThisWeek++
                totalRawEngagement += eng
                validPostCount++
                
                const dateKey = postDate.toISOString().split('T')[0]
                if (!dailyMap[dateKey]) dailyMap[dateKey] = 0
                dailyMap[dateKey] += eng
            }
        }
    })

    // 5. UPSERT DAILY GRAPH
    if (Object.keys(dailyMap).length > 0) {
        const dailyRows = Object.keys(dailyMap).map(date => ({
            user_id: user_id,
            date: date,
            platform: 'twitter',
            engagement: dailyMap[date]
        }))
        await supabase.from('daily_analytics').upsert(dailyRows, { onConflict: 'user_id,date,platform' })
    }

    // 6. SCORE
    const avgEng = validPostCount > 0 ? totalRawEngagement / validPostCount : 0
    const Hw = Math.min(Math.round((avgEng * 4.0) + 50 + p_variable), 1000)

    let newStreak = currentData?.consistency_weeks || 0
    let prevScore = currentData?.previous_handle_score || 0
    const lastUpdate = currentData?.last_updated ? new Date(currentData.last_updated) : new Date(0)
    
    if (lastUpdate < startOfWeek) {
        prevScore = currentData?.handle_score || 0
        if (postsThisWeek > 0) newStreak += 1
        else if ((now.getTime() - lastUpdate.getTime()) / 86400000 > 8) newStreak = 0
    } else {
        if (postsThisWeek > 0 && newStreak === 0) newStreak = 1
    }

    // 7. SAVE
    const { error: dbError } = await supabase.from('user_analytics').upsert({ 
        user_id: user_id, 
        x_score: Hw,
        x_post_count: postsThisWeek,
        x_engagement: totalRawEngagement,
        x_avg_engagement: Math.round(avgEng),
        consistency_weeks: newStreak,
        previous_handle_score: prevScore,
        last_updated: now.toISOString()
    }, { onConflict: 'user_id' })

    if (dbError) throw dbError

    // ✅ FIX: Added post_count back!
    return new Response(JSON.stringify({ 
        handle_score: Hw,
        post_count: postsThisWeek 
    }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: corsHeaders })
  }
})