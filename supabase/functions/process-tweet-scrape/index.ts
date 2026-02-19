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
    await supabase.from('daily_analytics').delete().eq('user_id', user_id).eq('platform', 'twitter');
    await supabase.from('best_posts').delete().eq('user_id', user_id).eq('platform', 'twitter');

    const cleanHandle = handle.replace('@', '').trim()
    const profileResp = await fetch(`https://twitter241.p.rapidapi.com/user?username=${cleanHandle}`, {
      headers: { 'x-rapidapi-key': RAPID_KEY!, 'x-rapidapi-host': 'twitter241.p.rapidapi.com' }
    })
    const profileData = await profileResp.json()
    const twitterID = profileData.result?.data?.user?.result?.rest_id || profileData.user?.result?.rest_id || profileData.data?.user?.result?.rest_id
    if (!twitterID) throw new Error("Twitter User Not Found")

    const tweetsResp = await fetch(`https://twitter241.p.rapidapi.com/user-tweets?user=${twitterID}&count=20`, {
      headers: { 'x-rapidapi-key': RAPID_KEY!, 'x-rapidapi-host': 'twitter241.p.rapidapi.com' }
    })
    const tweetsData = await tweetsResp.json()
    const instructions = tweetsData.result?.timeline?.instructions || []
    
    let rawItems: any[] = []
    instructions.forEach((instr: any) => {
        if (instr.entries) {
            instr.entries.forEach((e: any) => {
                if (e.content?.itemContent) rawItems.push(e.content.itemContent)
                if (e.content?.items) e.content.items.forEach((ni: any) => { if (ni.item?.itemContent) rawItems.push(ni.item.itemContent) })
            })
        }
        if (instr.type === "TimelinePinEntry" && instr.entry?.content?.itemContent) rawItems.push(instr.entry.content.itemContent)
    })

    const now = new Date()
    const startOfWeek = new Date(now)
    startOfWeek.setDate(now.getDate() - ((now.getDay() + 6) % 7))
    startOfWeek.setHours(0,0,0,0)
    const nowKey = now.toISOString().split('T')[0]

    let postsThisWeek = 0
    let totalRawEngagement = 0
    let bestPost: any = null
    let maxPowerScore = -1
    const dailyMap: Record<string, number> = {}

    rawItems.forEach((item: any) => {
        if (item.itemType !== "TimelineTweet") return
        const res = item.tweet_results?.result
        const legacy = res?.legacy || res?.tweet?.legacy
        if (legacy && legacy.created_at) {
            if (legacy.retweeted_status_result || legacy.retweeted_status_id_str) return;

            const postDate = new Date(legacy.created_at)
            const eng = (legacy.favorite_count || 0) + (legacy.retweet_count || 0) + (legacy.reply_count || 0)
            
            if (postDate >= startOfWeek) {
                postsThisWeek++
                totalRawEngagement += eng
                const powerScore = (legacy.favorite_count || 0) + ((legacy.reply_count || 0) * 2) + ((legacy.retweet_count || 0) * 3)
                if (powerScore > maxPowerScore) {
                    maxPowerScore = powerScore
                    bestPost = { 
                        text: legacy.full_text, 
                        likes: legacy.favorite_count, 
                        comments: legacy.reply_count, 
                        reposts: legacy.retweet_count, 
                        views: Number(res?.views?.count || 0),
                        date: postDate.toISOString().split('T')[0],
                        url: `https://x.com/${cleanHandle}/status/${res.rest_id || legacy.id_str}`
                    }
                }
                const dateKey = postDate.toISOString().split('T')[0]
                // 🛑 NEW HABIT TRACKER LOGIC: Add 1 for the post, instead of adding engagement
                dailyMap[dateKey] = (dailyMap[dateKey] || 0) + 1
            }
        }
    })

    // Upserting to 'engagement' column, but it now represents post count
    if (Object.keys(dailyMap).length > 0) {
        for (const [date, count] of Object.entries(dailyMap)) {
            await supabase.from('daily_analytics').upsert({ user_id, date, platform: 'twitter', engagement: count }, { onConflict: 'user_id,date,platform' })
        }
    }
    if (bestPost) await supabase.from('best_posts').upsert({ user_id, platform: 'twitter', post_text: bestPost.text, likes: bestPost.likes, comments: bestPost.comments, shares_reposts: bestPost.reposts, extra_metric: bestPost.views, post_url: bestPost.url, post_date: bestPost.date })

    const avgEng = postsThisWeek > 0 ? totalRawEngagement / postsThisWeek : 0
    const Hw = Math.min(Math.round((avgEng * 4.0) + 50 + p_variable), 1000)

    await supabase.from('user_analytics').upsert({ 
        user_id, x_score: Hw, x_post_count: postsThisWeek, x_engagement: totalRawEngagement,
        x_avg_engagement: Math.round(avgEng), last_updated: now.toISOString()
    }, { onConflict: 'user_id' })

    return new Response(JSON.stringify({ success: true, score: Hw }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
  } catch (err) { return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: corsHeaders }) }
})