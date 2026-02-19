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
    await supabase.from('daily_analytics').delete().eq('user_id', user_id).eq('platform', 'instagram');
    await supabase.from('best_posts').delete().eq('user_id', user_id).eq('platform', 'instagram');

    const cleanHandle = handle.replace('@', '')
    const response = await fetch(`https://instagram-scraper21.p.rapidapi.com/api/v1/full-posts?username=${cleanHandle}`, {
      headers: { 'x-rapidapi-key': RAPID_KEY!, 'x-rapidapi-host': 'instagram-scraper21.p.rapidapi.com' }
    });
    const result = await response.json()
    const posts = result.items || result.data?.posts || result.posts || []

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
        const likes = p.like_count || 0
        const comments = p.comment_count || 0
        const eng = likes + comments
        
        if (p.taken_at) {
            const postDate = new Date(p.taken_at * 1000)
            if (postDate >= startOfWeek) {
                postsThisWeek++
                totalRawEngagement += eng
                
                const powerScore = likes + (comments * 2)
                if (powerScore > maxPowerScore) {
                    maxPowerScore = powerScore
                    bestPost = { 
                        text: p.caption_text || "No Caption", 
                        likes, comments, 
                        date: postDate.toISOString().split('T')[0],
                        url: p.permalink || `https://instagram.com/p/${p.shortcode}/` 
                    }
                }

                const dateKey = postDate.toISOString().split('T')[0]
                // 🛑 NEW HABIT TRACKER LOGIC
                dailyMap[dateKey] = (dailyMap[dateKey] || 0) + 1
            }
        }
    })

    if (Object.keys(dailyMap).length > 0) {
        for (const [date, count] of Object.entries(dailyMap)) {
            await supabase.from('daily_analytics').upsert({ user_id, date, platform: 'instagram', engagement: count }, { onConflict: 'user_id,date,platform' })
        }
    }

    if (bestPost) {
        await supabase.from('best_posts').upsert({
            user_id, platform: 'instagram', post_text: bestPost.text,
            likes: bestPost.likes, comments: bestPost.comments, post_url: bestPost.url, post_date: bestPost.date
        })
    }

    const avgEng = postsThisWeek > 0 ? totalRawEngagement / postsThisWeek : 0
    const Hw = Math.min(Math.round((avgEng * 0.7) + (1.2 * 0.3) + p_variable), 1000)
    
    await supabase.from('user_analytics').upsert({ 
      user_id, insta_score: Hw, insta_post_count: postsThisWeek, insta_engagement: totalRawEngagement,
      insta_avg_engagement: Math.round(avgEng), last_updated: now.toISOString()
    }, { onConflict: 'user_id' })

    return new Response(JSON.stringify({ success: true, score: Hw }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
  } catch (err) { return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: corsHeaders }) }
})