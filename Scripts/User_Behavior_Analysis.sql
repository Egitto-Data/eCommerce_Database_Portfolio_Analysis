/* =============================================================================
   REPEAT VISITOR ANALYSIS: DISTRIBUTION OF REPEAT SESSIONS PER USER
   
   Purpose: 
     Evaluate repeat session frequency per user between 2014-01-01 and 2014-11-01 
     to help Tom quantify customer retention and adjust marketing bidding models 
     to account for post-acquisition repeat value.
   ============================================================================= */

WITH first_sessions AS (
    -- Step 1: Identify initial customer acquisition sessions (is_repeat_session = 0)
    SELECT 
        user_id,
        website_session_id                                              AS new_session_id
    FROM website_sessions
    WHERE created_at >= '2014-01-01' 
      AND created_at < '2014-11-01'
      AND is_repeat_session = 0
),
user_repeat_counts AS (
    -- Step 2: Join repeat sessions to original users and count total repeat sessions per user
    SELECT 
        fs.user_id,
        COUNT(ws.website_session_id)                                    AS repeat_sessions
    FROM first_sessions fs
    LEFT JOIN website_sessions ws
           ON fs.user_id = ws.user_id
          AND ws.is_repeat_session = 1
          AND ws.website_session_id > fs.new_session_id -- 
          AND ws.created_at >= '2014-01-01'
          AND ws.created_at < '2014-11-01'
    GROUP BY fs.user_id
)
-- Step 3: Aggregate count of users grouped by their total number of repeat sessions
SELECT 
    repeat_sessions,
    COUNT(DISTINCT user_id)                                             AS users
FROM user_repeat_counts
GROUP BY repeat_sessions
ORDER BY repeat_sessions ASC;

/* =============================================================================
   REPEAT VISITOR ANALYSIS: TIME ELAPSED BETWEEN FIRST & SECOND SESSIONS
   
   Purpose: 
     Calculate the AVG, MIN, and MAX days elapsed between a user's initial 
     acquisition session and their very next repeat session (second session)
     for the cohort acquired in 2014.
   ============================================================================= */

WITH first_sessions AS (
    -- Step 1: Identify initial customer acquisition sessions (is_repeat_session = 0)
    SELECT 
        user_id,
        website_session_id                                              AS new_session_id,
        created_at                                                      AS new_session_created_at
    FROM website_sessions
    WHERE created_at >= '2014-01-01' 
      AND created_at < '2014-11-01'
      AND is_repeat_session = 0
),
second_sessions AS (
    -- Step 2: Identify the FIRST repeat session (2nd overall session) per user
    SELECT 
        fs.user_id,
        fs.new_session_created_at,
        MIN(ws.created_at)                                              AS second_session_created_at
    FROM first_sessions fs
    INNER JOIN website_sessions ws
            ON fs.user_id = ws.user_id
           AND ws.is_repeat_session = 1
           AND ws.website_session_id > fs.new_session_id
           AND ws.created_at >= '2014-01-01'
           AND ws.created_at < '2014-11-01'
    GROUP BY 
        fs.user_id,
        fs.new_session_created_at
),
user_days_between AS (
    -- Step 3: Calculate days elapsed between 1st and 2nd sessions per user
    SELECT 
        user_id,
        DATEDIFF(second_session_created_at, new_session_created_at)     AS days_first_to_second
    FROM second_sessions
)
-- Step 4: Aggregate population statistics across returning users
SELECT 
    ROUND(AVG(days_first_to_second), 2)                                 AS avg_days_first_to_second,
    MIN(days_first_to_second)                                           AS min_days_first_to_second,
    MAX(days_first_to_second)                                           AS max_days_first_to_second
FROM user_days_between;

/* =============================================================================
   CHANNEL PATTERN ANALYSIS: NEW VS. REPEAT TRAFFIC BREAKDOWN
   
   Purpose: 
     Classify traffic into marketing channel categories (Organic, Direct, Paid Brand, 
     Paid Non-Brand, Paid Social) and evaluate whether returning visitors come through
     free channels or require additional paid acquisition spend.
   ============================================================================= */

WITH labeled_sessions AS (
    -- Step 1: Map raw UTM and referer parameters into high-level business channels
    SELECT 
        website_session_id,
        is_repeat_session,
        CASE 
            WHEN utm_source IS NULL AND http_referer IS NULL 
                THEN 'direct_type_in'
            WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') 
                THEN 'organic_search'
            WHEN utm_campaign = 'nonbrand' 
                THEN 'paid_nonbrand'
            WHEN utm_campaign = 'brand' 
                THEN 'paid_brand'
            WHEN utm_source = 'socialbook' 
                THEN 'paid_social'
            ELSE 'other'
        END AS channel_group
    FROM website_sessions
    WHERE created_at >= '2014-01-01' 
      AND created_at < '2014-11-01'
)
-- Step 2: Pivot session counts into new vs. repeat metrics per channel
SELECT 
    channel_group,
    COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id END)  AS new_sessions,
    COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id END)  AS repeat_sessions
FROM labeled_sessions
GROUP BY channel_group
ORDER BY repeat_sessions DESC;

/* =============================================================================
   NEW VS. REPEAT PERFORMANCE ANALYSIS
   
   Purpose: 
     Compare key performance indicators (Sessions, Orders, Conversion Rate, 
     Total Revenue, and Revenue per Session) between initial acquisition sessions 
     (is_repeat_session = 0) and returning sessions (is_repeat_session = 1) 
     for the 2014 period.
   ============================================================================= */

WITH session_order_data AS (
    -- Step 1: Join sessions to orders to aggregate session-level monetary metrics
    SELECT 
        ws.is_repeat_session,
        COUNT(DISTINCT ws.website_session_id)                           AS total_sessions,
        COUNT(DISTINCT o.order_id)                                      AS total_orders,
        SUM(o.price_usd)                                                AS total_revenue
    FROM website_sessions ws
    LEFT JOIN orders o
           ON ws.website_session_id = o.website_session_id
    WHERE ws.created_at >= '2014-01-01' 
      AND ws.created_at < '2014-11-01'
    GROUP BY ws.is_repeat_session
)
-- Step 2: Calculate conversion rate and revenue per session with safe division
SELECT 
    is_repeat_session,
    total_sessions                                                      AS sessions,
    total_orders                                                        AS orders,
    ROUND(total_orders * 100.0 / NULLIF(total_sessions, 0), 2)          AS conv_rate_pct,
    ROUND(COALESCE(total_revenue, 0), 2)                                AS total_revenue_usd,
    ROUND(COALESCE(total_revenue, 0) / NULLIF(total_sessions, 0), 2)    AS rev_per_session_usd
FROM session_order_data
ORDER BY is_repeat_session ASC;