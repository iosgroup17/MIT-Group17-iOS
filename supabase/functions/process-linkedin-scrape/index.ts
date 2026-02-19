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
    const RAPID_KEY = Deno.env.get('RAPIDAPI_KEY')
    const supabase = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', { auth: { persistSession: false } })

    // 1. 🛑 CLEAN SLATE
    await supabase.from('daily_analytics').delete().eq('user_id', user_id).eq('platform', 'linkedin');
    await supabase.from('best_posts').delete().eq('user_id', user_id).eq('platform', 'linkedin');

    const cleanHandle = handle.replace('@', '').split('/').filter(Boolean).pop()
    const postsResp = await fetch(`https://fresh-linkedin-scraper-api.p.rapidapi.com/api/v1/user/posts?username=${cleanHandle}`, {
      headers: { 'x-rapidapi-key': RAPID_KEY!, 'x-rapidapi-host': 'fresh-linkedin-scraper-api.p.rapidapi.com' }
    })
    const result = await postsResp.json()
    const posts = result.data || []

    const now = new Date()
    const startOfWeek = new Date(now)
    startOfWeek.setDate(now.getDate() - ((now.getDay() + 6) % 7)) 
    startOfWeek.setHours(0, 0, 0, 0)
    const nowKey = now.toISOString().split('T')[0]

    let postsThisWeek = 0
    let totalRawEngagement = 0
    const dailyMap: Record<string, number> = {}
    let bestPost: any = null
    let maxPowerScore = -1

    posts.forEach((p: any) => {
        if (p.is_repost || p.reshared || p.text?.includes("RT @") || p.author?.id !== result.data?.id) return;

        const act = p.activity || {}
        const likes = Number(act.num_likes || 0)
        const comments = Number(act.num_comments || 0)
        const shares = Number(act.num_shares || 0)
        const eng = likes + comments
        
        let postDate = p.created_at ? new Date(p.created_at) : null
        if (!postDate && p.postedAtTimestamp) {
             const ts = p.postedAtTimestamp > 10000000000 ? p.postedAtTimestamp : p.postedAtTimestamp * 1000
             postDate = new Date(ts)
        }

        if (postDate && postDate >= startOfWeek) {
            postsThisWeek++
            totalRawEngagement += eng
            const powerScore = likes + (comments * 2) + (shares * 3)
            if (powerScore > maxPowerScore) {
                maxPowerScore = powerScore
                bestPost = { 
                    text: p.text || "No Text", 
                    likes, comments, shares, 
                    date: postDate.toISOString().split('T')[0],
                    url: p.url || p.post_url 
                }
            }
            const dateKey = postDate.toISOString().split('T')[0]
            // 🛑 NEW HABIT TRACKER LOGIC
            dailyMap[dateKey] = (dailyMap[dateKey] || 0) + 1
        }
    })

    if (Object.keys(dailyMap).length > 0) {
        for (const [date, count] of Object.entries(dailyMap)) {
            await supabase.from('daily_analytics').upsert({ user_id, date, platform: 'linkedin', engagement: count }, { onConflict: 'user_id,date,platform' })
        }
    }

    if (bestPost) {
        await supabase.from('best_posts').upsert({
            user_id, platform: 'linkedin', post_text: bestPost.text,
            likes: bestPost.likes, comments: bestPost.comments, shares_reposts: bestPost.shares, post_url: bestPost.url, post_date: bestPost.date
        })
    }

    const avgEng = postsThisWeek > 0 ? totalRawEngagement / postsThisWeek : 0
    const Hw = Math.min(Math.round((avgEng * 3.0) + 100 + p_variable), 1000)

    await supabase.from('user_analytics').upsert({ 
        user_id, linkedin_score: Hw, linkedin_post_count: postsThisWeek, linkedin_engagement: totalRawEngagement,
        linkedin_avg_engagement: Math.round(avgEng), last_updated: now.toISOString()
    }, { onConflict: 'user_id' })

    return new Response(JSON.stringify({ success: true, score: Hw }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
  } catch (err) { return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: corsHeaders }) }
})