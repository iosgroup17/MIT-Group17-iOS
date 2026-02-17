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
    console.log(`\n=== 👔 LINKEDIN SCRAPE V7 (FIX): ${handle} ===`)

    const RAPID_KEY = Deno.env.get('RAPIDAPI_KEY')
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // 1. FETCH STATE
    const { data: currentData } = await supabase.from('user_analytics').select('*').eq('user_id', user_id).single()

    // 2. FETCH DATA
    const cleanHandle = handle.replace('@', '').split('/').filter(Boolean).pop()
    const postsResp = await fetch(`https://fresh-linkedin-scraper-api.p.rapidapi.com/api/v1/user/posts?username=${cleanHandle}`, {
      headers: { 'x-rapidapi-key': RAPID_KEY!, 'x-rapidapi-host': 'fresh-linkedin-scraper-api.p.rapidapi.com' }
    })
    const result = await postsResp.json()
    const posts = result.data || []

    // 3. ANALYZE
    const now = new Date()
    const startOfWeek = new Date(now)
    startOfWeek.setDate(now.getDate() - ((now.getDay() + 6) % 7)) 
    startOfWeek.setHours(0, 0, 0, 0)

    let postsThisWeek = 0
    let totalRawEngagement = 0
    const dailyMap: Record<string, number> = {}

    posts.forEach((p: any) => {
        const act = p.activity || {}
        const eng = (Number(act.num_likes || 0) + Number(act.num_comments || 0))
        
        let postDate: Date | null = null
        if (p.created_at) postDate = new Date(p.created_at)
        else if (p.postedAtTimestamp) {
             // Handle potential milliseconds vs seconds
             const ts = p.postedAtTimestamp > 10000000000 ? p.postedAtTimestamp : p.postedAtTimestamp * 1000
             postDate = new Date(ts)
        }

        if (postDate && postDate >= startOfWeek) {
            postsThisWeek++
            totalRawEngagement += eng
            
            // Daily Graph Data
            const dateKey = postDate.toISOString().split('T')[0]
            if (!dailyMap[dateKey]) dailyMap[dateKey] = 0
            dailyMap[dateKey] += eng
        }
    })

    // 4. UPSERT DAILY GRAPH
    if (Object.keys(dailyMap).length > 0) {
        const dailyRows = Object.keys(dailyMap).map(date => ({
            user_id: user_id,
            date: date,
            platform: 'linkedin',
            engagement: dailyMap[date]
        }))
        await supabase.from('daily_analytics').upsert(dailyRows, { onConflict: 'user_id,date,platform' })
    }

    // 5. SUMMARY SAVING
    const avgEng = postsThisWeek > 0 ? totalRawEngagement / postsThisWeek : 0
    const Hw = Math.min(Math.round((avgEng * 3.0) + 100 + p_variable), 1000)

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

    const { error: dbError } = await supabase.from('user_analytics').upsert({ 
        user_id: user_id, 
        linkedin_score: Hw,
        linkedin_post_count: postsThisWeek,
        linkedin_engagement: totalRawEngagement,
        linkedin_avg_engagement: Math.round(avgEng),
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