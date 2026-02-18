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
    console.log(`\n=== 🚀 INSTA SCRAPE V7 (FIX): ${handle} ===`)

    const RAPID_KEY = Deno.env.get('RAPIDAPI_KEY')
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    const { data: currentData } = await supabase.from('user_analytics').select('*').eq('user_id', user_id).single()

    const cleanHandle = handle.replace('@', '')
    const response = await fetch(`https://instagram-scraper21.p.rapidapi.com/api/v1/full-posts?username=${cleanHandle}&limit=10`, {
      headers: { 'x-rapidapi-key': RAPID_KEY!, 'x-rapidapi-host': 'instagram-scraper21.p.rapidapi.com' }
    });
    const result = await response.json()
    const posts = result.data?.posts || result.posts || []

    const now = new Date()
    const startOfWeek = new Date(now)
    startOfWeek.setDate(now.getDate() - ((now.getDay() + 6) % 7))
    startOfWeek.setHours(0, 0, 0, 0)

    let postsThisWeek = 0
    let totalRawEngagement = 0
    const dailyMap: Record<string, number> = {}
    
    posts.forEach((p: any) => {
        const eng = (p.like_count || 0) + (p.comment_count || 0)
        
        if (p.taken_at) {
            const postDate = new Date(p.taken_at * 1000)
            if (postDate >= startOfWeek) {
                postsThisWeek++
                totalRawEngagement += eng
                
                // ✅ FIX: Use local string to prevent timezone drift
                const dateKey = postDate.toLocaleDateString('en-CA') 
                if (!dailyMap[dateKey]) dailyMap[dateKey] = 0
                dailyMap[dateKey] += eng
            }
        }
    })

    if (Object.keys(dailyMap).length > 0) {
        const dailyRows = Object.keys(dailyMap).map(date => ({
            user_id: user_id,
            date: date,
            platform: 'instagram',
            engagement: dailyMap[date]
        }))
        await supabase.from('daily_analytics').upsert(dailyRows, { onConflict: 'user_id,date,platform' })
    }

    const avgEng = postsThisWeek > 0 ? totalRawEngagement / postsThisWeek : 0
    const Hw = Math.min(Math.round((avgEng * 0.7) + (1.2 * 0.3) + p_variable), 1000)

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
      insta_score: Hw,
      insta_post_count: postsThisWeek,
      insta_engagement: totalRawEngagement,
      insta_avg_engagement: Math.round(avgEng),
      consistency_weeks: newStreak,
      previous_handle_score: prevScore,
      last_updated: now.toISOString()
  }, { onConflict: 'user_id' })

    if (dbError) throw dbError

    return new Response(JSON.stringify({ 
        handle_score: Hw,
        post_count: postsThisWeek 
    }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
    
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: corsHeaders })
  }
})