# HandleApp - Apify Web Scraping & Analytics Architecture

## Overview

This document describes HandleApp's innovative analytics approach using **Apify web scrapers** integrated with **Supabase** instead of direct API calls. This architecture reduces costs by approximately 70% during the startup phase while maintaining reliable data collection.

---

## Why Web Scraping Over APIs?

### Cost Comparison

| Solution | Monthly Cost | Data Points | Cost per 1000 |
|----------|-------------|-------------|---------------|
| **Twitter API v2** | $100-500 | 10k-100k tweets | $10-50 |
| **Instagram Graph API** | $0-200 | Limited by rate | Variable |
| **LinkedIn API** | Enterprise only | N/A | High |
| **Apify Web Scraping** | $49-99 | Unlimited* | <$1 |

*Subject to Apify fair use policy and scraping limits

### Advantages of Web Scraping
1. **Cost Efficiency:** 70-90% cheaper than official APIs
2. **No Rate Limits:** More flexible data collection
3. **Richer Data:** Access to public data not available via APIs
4. **Startup Friendly:** Affordable for MVP and early-stage
5. **Easy Migration:** Can switch to APIs later without app changes

### Trade-offs
- **Maintenance:** Scrapers may need updates if platforms change HTML
- **Legal Considerations:** Complies with public data scraping (robots.txt compliant)
- **Data Freshness:** Scheduled scraping vs real-time API calls
- **Reliability:** Dependent on Apify uptime and platform stability

---

## Architecture Diagram

```
┌─────────────────┐
│   iOS App       │
│   (HandleApp)   │
└────────┬────────┘
         │ REST API Calls
         │ (Supabase Client)
         ▼
┌─────────────────┐
│   Supabase      │
│   (PostgreSQL)  │◄──────┐
└────────┬────────┘       │
         │                │ Webhook/Direct Insert
         │ Triggers       │
         ▼                │
┌─────────────────┐       │
│  Supabase Edge  │       │
│  Functions      │       │
└────────┬────────┘       │
         │ HTTP Requests  │
         │                │
         ▼                │
┌─────────────────────────┴──┐
│   Apify Platform           │
│   ┌─────────────────────┐  │
│   │ Twitter Scraper     │  │
│   │ (Actor)             │  │
│   └─────────────────────┘  │
│   ┌─────────────────────┐  │
│   │ Instagram Scraper   │  │
│   │ (Actor)             │  │
│   └─────────────────────┘  │
│   ┌─────────────────────┐  │
│   │ LinkedIn Scraper    │  │
│   │ (Actor)             │  │
│   └─────────────────────┘  │
└────────────────────────────┘
         │
         ▼
┌────────────────────────────┐
│  Social Media Platforms    │
│  (Public Data)             │
│  - Twitter/X               │
│  - Instagram               │
│  - LinkedIn                │
└────────────────────────────┘
```

---

## Implementation Details

### 1. Apify Actors (Scrapers)

#### Twitter/X Scraper Actor
```javascript
// Apify Actor configuration
{
  "actorId": "apify/twitter-scraper",
  "input": {
    "handles": ["@userhandle"],
    "tweetsDesired": 100,
    "includeAnalytics": true,
    "fields": [
      "likes",
      "retweets", 
      "replies",
      "views",
      "timestamp"
    ]
  },
  "schedule": "0 */6 * * *" // Every 6 hours
}
```

#### Instagram Scraper Actor
```javascript
{
  "actorId": "apify/instagram-scraper",
  "input": {
    "username": "userhandle",
    "resultsLimit": 50,
    "includeInsights": true,
    "fields": [
      "likes",
      "comments",
      "saves",
      "shares",
      "reach",
      "timestamp"
    ]
  },
  "schedule": "0 */6 * * *"
}
```

#### LinkedIn Scraper Actor
```javascript
{
  "actorId": "apify/linkedin-scraper",
  "input": {
    "profileUrl": "linkedin.com/in/username",
    "postsLimit": 50,
    "includeAnalytics": true,
    "fields": [
      "reactions",
      "comments",
      "shares",
      "views",
      "timestamp"
    ]
  },
  "schedule": "0 */6 * * *"
}
```

### 2. Supabase Database Schema

#### `analytics_raw` Table
Stores raw scraped data before processing
```sql
CREATE TABLE analytics_raw (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  platform TEXT NOT NULL, -- 'twitter', 'instagram', 'linkedin'
  post_id TEXT NOT NULL,
  post_url TEXT,
  scraped_data JSONB NOT NULL, -- Raw JSON from Apify
  scraped_at TIMESTAMP DEFAULT NOW(),
  processed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_analytics_raw_user ON analytics_raw(user_id);
CREATE INDEX idx_analytics_raw_platform ON analytics_raw(platform);
CREATE INDEX idx_analytics_raw_processed ON analytics_raw(processed);
```

#### `analytics_processed` Table
Normalized analytics data for app consumption
```sql
CREATE TABLE analytics_processed (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  post_id UUID REFERENCES posts(id),
  platform TEXT NOT NULL,
  
  -- Engagement metrics
  likes INTEGER DEFAULT 0,
  comments INTEGER DEFAULT 0,
  shares INTEGER DEFAULT 0,
  retweets INTEGER DEFAULT 0,
  saves INTEGER DEFAULT 0,
  views INTEGER DEFAULT 0,
  
  -- Calculated metrics
  engagement_rate DECIMAL(5,2),
  handle_score DECIMAL(8,2),
  
  -- Timestamps
  post_published_at TIMESTAMP,
  metrics_collected_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_analytics_user_platform ON analytics_processed(user_id, platform);
CREATE INDEX idx_analytics_post ON analytics_processed(post_id);
```

#### `scraping_jobs` Table
Track scraping job status and history
```sql
CREATE TABLE scraping_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  platform TEXT NOT NULL,
  apify_actor_id TEXT NOT NULL,
  apify_run_id TEXT,
  status TEXT DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed'
  items_scraped INTEGER DEFAULT 0,
  error_message TEXT,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_jobs_user_platform ON scraping_jobs(user_id, platform);
CREATE INDEX idx_jobs_status ON scraping_jobs(status);
```

### 3. Supabase Edge Functions

#### Function: `trigger-apify-scrape`
Initiates Apify scraping job
```typescript
// supabase/functions/trigger-apify-scrape/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { userId, platform, handle } = await req.json()
  
  // Start Apify actor
  const apifyResponse = await fetch(
    `https://api.apify.com/v2/acts/${getActorId(platform)}/runs`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('APIFY_API_TOKEN')}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        handle: handle,
        webhooks: [{
          eventTypes: ['ACTOR.RUN.SUCCEEDED'],
          requestUrl: `${Deno.env.get('SUPABASE_URL')}/functions/v1/process-apify-results`
        }]
      })
    }
  )
  
  const run = await apifyResponse.json()
  
  // Log job in database
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL'),
    Deno.env.get('SUPABASE_SERVICE_KEY')
  )
  
  await supabase.from('scraping_jobs').insert({
    user_id: userId,
    platform: platform,
    apify_actor_id: getActorId(platform),
    apify_run_id: run.data.id,
    status: 'running',
    started_at: new Date().toISOString()
  })
  
  return new Response(JSON.stringify({ success: true, runId: run.data.id }))
})

function getActorId(platform: string): string {
  const actors = {
    'twitter': 'apify/twitter-scraper',
    'instagram': 'apify/instagram-scraper',
    'linkedin': 'apify/linkedin-scraper'
  }
  return actors[platform]
}
```

#### Function: `process-apify-results`
Webhook endpoint to receive and process scraped data
```typescript
// supabase/functions/process-apify-results/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const webhook = await req.json()
  const runId = webhook.resource.id
  
  // Fetch scraped data from Apify
  const dataResponse = await fetch(
    `https://api.apify.com/v2/actor-runs/${runId}/dataset/items`,
    {
      headers: {
        'Authorization': `Bearer ${Deno.env.get('APIFY_API_TOKEN')}`
      }
    }
  )
  
  const scrapedData = await dataResponse.json()
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL'),
    Deno.env.get('SUPABASE_SERVICE_KEY')
  )
  
  // Store raw data
  for (const item of scrapedData) {
    await supabase.from('analytics_raw').insert({
      user_id: item.userId,
      platform: item.platform,
      post_id: item.postId,
      post_url: item.url,
      scraped_data: item,
      scraped_at: new Date().toISOString()
    })
  }
  
  // Update job status
  await supabase.from('scraping_jobs')
    .update({
      status: 'completed',
      items_scraped: scrapedData.length,
      completed_at: new Date().toISOString()
    })
    .eq('apify_run_id', runId)
  
  // Trigger processing
  await processAnalytics(scrapedData)
  
  return new Response(JSON.stringify({ success: true }))
})

async function processAnalytics(data: any[]) {
  // Transform and normalize data
  // Calculate engagement metrics
  // Update analytics_processed table
}
```

### 4. iOS App Integration

#### Swift Client Code
```swift
// SupabaseManager.swift
class SupabaseManager {
    static let shared = SupabaseManager()
    private let supabase: SupabaseClient
    
    // Trigger scraping for user's connected platforms
    func triggerAnalyticsScrape(for userId: String) async throws {
        let platforms = ["twitter", "instagram", "linkedin"]
        
        for platform in platforms {
            guard let handle = getConnectedHandle(for: platform) else { continue }
            
            try await supabase.functions.invoke(
                "trigger-apify-scrape",
                options: FunctionInvokeOptions(
                    body: [
                        "userId": userId,
                        "platform": platform,
                        "handle": handle
                    ]
                )
            )
        }
    }
    
    // Fetch processed analytics
    func fetchAnalytics(for userId: String, platform: String?) async throws -> [AnalyticsData] {
        var query = supabase
            .from("analytics_processed")
            .select()
            .eq("user_id", userId)
            .order("metrics_collected_at", ascending: false)
            .limit(100)
        
        if let platform = platform {
            query = query.eq("platform", platform)
        }
        
        let response: [AnalyticsData] = try await query.execute().value
        return response
    }
    
    // Real-time subscription to new analytics
    func subscribeToAnalytics(userId: String, callback: @escaping ([AnalyticsData]) -> Void) {
        let channel = supabase.channel("analytics-\(userId)")
        
        channel
            .on(.postgresChanges(
                event: .insert,
                schema: "public",
                table: "analytics_processed",
                filter: "user_id=eq.\(userId)"
            )) { payload in
                if let newData = payload.new as? AnalyticsData {
                    callback([newData])
                }
            }
            .subscribe()
    }
}
```

### 5. Scheduling Strategy

#### Scraping Frequency
- **Every 6 hours:** Routine data collection
- **On-demand:** User-triggered refresh
- **Daily summary:** Aggregate calculations at midnight
- **Weekly reports:** Performance trends and insights

#### Apify Scheduler Configuration
```json
{
  "schedule": {
    "cron": "0 */6 * * *",
    "timezone": "UTC"
  },
  "notifications": {
    "webhook": "https://[project].supabase.co/functions/v1/process-apify-results",
    "onSuccess": true,
    "onFailure": true
  }
}
```

---

## Data Processing Pipeline

### Step 1: Raw Data Collection
Apify scrapers collect data → Store in `analytics_raw` table

### Step 2: Data Validation
- Check for duplicate posts
- Validate metrics ranges
- Filter out spam/bot content

### Step 3: Normalization
- Platform-specific metrics → Universal format
- Calculate engagement rate
- Compute Handle Score

### Step 4: Storage
- Insert into `analytics_processed` table
- Link to existing posts
- Update user statistics

### Step 5: Real-time Sync
- Push notification to iOS app
- Update UI with new metrics
- Trigger analytics refresh

---

## Handle Score Algorithm

Proprietary engagement metric calculation:

```python
def calculate_handle_score(metrics):
    """
    Handle Score = Weighted engagement metric
    Range: 0-100
    """
    weights = {
        'likes': 1.0,
        'comments': 3.0,      # Comments are more valuable
        'shares': 5.0,        # Shares are most valuable
        'saves': 4.0,         # Instagram-specific
        'retweets': 5.0,      # Twitter-specific
        'views': 0.01         # Views are less valuable
    }
    
    total_engagement = sum([
        metrics.get(key, 0) * weight 
        for key, weight in weights.items()
    ])
    
    # Normalize to 0-100 scale with logarithmic curve
    score = min(100, (log(total_engagement + 1) / log(1000)) * 100)
    
    return round(score, 2)
```

---

## Cost Analysis

### Monthly Operational Costs

| Service | Tier | Cost | Usage |
|---------|------|------|-------|
| **Apify** | Starter | $49 | 50k actor operations |
| **Supabase** | Free/Pro | $0-25 | 500MB DB, 2GB bandwidth |
| **Total** | - | **$49-74** | 1000+ users |

### Comparison with API Approach

| Approach | Cost/Month | Users Supported | Cost per User |
|----------|------------|-----------------|---------------|
| **Web Scraping** | $49-74 | 1000-5000 | $0.01-0.07 |
| **Direct APIs** | $500-2000 | 1000-5000 | $0.10-2.00 |
| **Savings** | **~90%** | Same | **~95%** |

---

## Migration Path to APIs

When the business scales and can afford direct API costs:

### Phase 1: Dual Mode (Current + APIs)
- Keep Apify for bulk historical data
- Add direct API calls for real-time updates
- Compare data quality

### Phase 2: Gradual Transition
- Move high-priority users to direct APIs
- Keep Apify for others
- Monitor cost vs value

### Phase 3: Full API Integration
- Deprecate web scraping
- 100% direct API usage
- Enhanced features (webhooks, streaming)

**App Code Changes Required:** Minimal - Just swap data source in SupabaseManager

---

## Legal & Compliance

### Scraping Best Practices
✅ Only scrape public data  
✅ Respect robots.txt  
✅ Rate limiting and delays  
✅ User consent for their own data  
✅ Transparent about data collection  
✅ Comply with platform ToS for public data  

### Terms of Service Considerations
- Web scraping of public data is generally legal (hiQ vs LinkedIn precedent)
- Users authenticate to grant permission for their own data
- No circumvention of technical protection measures
- Rate-limited to avoid server strain

---

## Monitoring & Alerts

### Success Metrics
- Scraping success rate > 95%
- Data freshness < 6 hours
- Processing time < 5 minutes
- Error rate < 5%

### Alert Triggers
- Scraper failure 3+ times
- Data processing errors
- Apify quota approaching limit
- Supabase storage > 80%

### Monitoring Dashboard
```typescript
// Monitor scraping health
SELECT 
  platform,
  COUNT(*) as total_jobs,
  SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as successful,
  AVG(items_scraped) as avg_items,
  AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) as avg_duration_seconds
FROM scraping_jobs
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY platform;
```

---

## Future Enhancements

### Short-term (3-6 months)
- Add retry logic for failed scrapes
- Implement data deduplication
- Create scraping quality scores
- Add competitor tracking

### Long-term (6-12 months)
- Real-time scraping for premium users
- Historical trend analysis
- Predictive analytics using ML
- Custom scraper development

---

## Summary

HandleApp's Apify + Supabase architecture provides:
- **70-90% cost savings** compared to direct APIs
- **Scalable foundation** for startup phase
- **Easy migration path** to APIs when needed
- **Reliable data collection** with scheduled scraping
- **Real-time sync** to iOS app via Supabase

This innovative approach makes advanced social media analytics accessible to bootstrapped startups and small businesses while maintaining high data quality and user experience.

---

**Document Version:** 1.0  
**Last Updated:** January 28, 2026  
**Status:** Technical Specification - Implementation Ready
