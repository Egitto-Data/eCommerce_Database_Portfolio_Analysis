/* =============================================================================
   PROJECT-1 E-COMMERCE PERFORMANCE ANALYSIS & A/B TESTING EVALUATION
   
   Purpose: 
     Comprehensive analytical suite evaluating website traffic volume, acquisition 
     channels, funnel conversion rates, and the financial impact of A/B tests 
     (custom landing pages ) prior to 2012-11-27.
   ============================================================================= */


-- -----------------------------------------------------------------------------
-- Q1: GSearch Monthly Session & Order Trends
-- Purpose: Measure monthly volume growth and conversion rate for GSearch traffic.
-- -----------------------------------------------------------------------------
SELECT 
    YEAR(ws.created_at)                                                AS yr,
    MONTH(ws.created_at)                                               AS mo,
    COUNT(ws.website_session_id)                                       AS sessions,
    COUNT(o.order_id)                                                  AS orders,
    ROUND(COUNT(o.order_id) * 100.0 / COUNT(ws.website_session_id), 2) AS conv_rate_pct
FROM website_sessions ws
LEFT JOIN orders o 
       ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-27'
  AND ws.utm_source = 'gsearch'
GROUP BY YEAR(ws.created_at), MONTH(ws.created_at);


-- -----------------------------------------------------------------------------
-- Q2: GSearch Monthly Trend Split by Brand vs. Nonbrand Campaign
-- Purpose: Monitor Brand vs. Nonbrand session and order volume growth separately.
-- -----------------------------------------------------------------------------
SELECT 
    YEAR(ws.created_at)                                                               AS yr,
    MONTH(ws.created_at)                                                              AS mo,
    COUNT(CASE WHEN ws.utm_campaign = 'nonbrand' THEN ws.website_session_id END)      AS nonbrand_sessions,
    COUNT(CASE WHEN ws.utm_campaign = 'nonbrand' THEN o.order_id END)                 AS nonbrand_orders,
    COUNT(CASE WHEN ws.utm_campaign = 'brand'    THEN ws.website_session_id END)      AS brand_sessions,
    COUNT(CASE WHEN ws.utm_campaign = 'brand'    THEN o.order_id END)                 AS brand_orders
FROM website_sessions ws
LEFT JOIN orders o 
       ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-27'
  AND ws.utm_source = 'gsearch'
GROUP BY YEAR(ws.created_at), MONTH(ws.created_at);


-- -----------------------------------------------------------------------------
-- Q3: GSearch Nonbrand Monthly Trend Split by Device Type
-- Purpose: Analyze device split (Desktop vs. Mobile) within paid Nonbrand search.
-- -----------------------------------------------------------------------------
SELECT 
    YEAR(ws.created_at)                                                               AS yr,
    MONTH(ws.created_at)                                                              AS mo,
    COUNT(CASE WHEN ws.device_type = 'desktop' THEN ws.website_session_id END)        AS desktop_sessions,
    COUNT(CASE WHEN ws.device_type = 'desktop' THEN o.order_id END)                   AS desktop_orders,
    COUNT(CASE WHEN ws.device_type = 'mobile'  THEN ws.website_session_id END)        AS mobile_sessions,
    COUNT(CASE WHEN ws.device_type = 'mobile'  THEN o.order_id END)                   AS mobile_orders
FROM website_sessions ws
LEFT JOIN orders o 
       ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-27'
  AND ws.utm_source = 'gsearch'
  AND ws.utm_campaign = 'nonbrand'
GROUP BY YEAR(ws.created_at), MONTH(ws.created_at);


-- -----------------------------------------------------------------------------
-- Q4: Monthly Channel Mix Breakdown
-- Purpose: Evaluate overall acquisition channel mix across paid, organic, and direct.
-- -----------------------------------------------------------------------------
SELECT 
    YEAR(created_at)                                                                            AS yr,
    MONTH(created_at)                                                                           AS mo,
    COUNT(CASE WHEN utm_source = 'gsearch' AND utm_campaign IN ('nonbrand', 'brand') THEN website_session_id END) AS gsearch_paid_sessions,
    COUNT(CASE WHEN utm_source = 'bsearch' AND utm_campaign IN ('nonbrand', 'brand') THEN website_session_id END) AS bsearch_paid_sessions,
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL                   THEN website_session_id END) AS organic_search_sessions,
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL                       THEN website_session_id END) AS direct_type_in_sessions
FROM website_sessions
WHERE created_at < '2012-11-27'
GROUP BY YEAR(created_at), MONTH(created_at);


-- -----------------------------------------------------------------------------
-- Q5: Overall Website Monthly Session-to-Order Conversion Rate
-- Purpose: Measure site-wide conversion rate progression across all channels.
-- -----------------------------------------------------------------------------
SELECT 
    YEAR(ws.created_at)                                                AS yr,
    MONTH(ws.created_at)                                               AS mo,
    COUNT(ws.website_session_id)                                       AS total_sessions,
    COUNT(o.order_id)                                                  AS total_orders,
    ROUND(COUNT(o.order_id) * 100.0 / COUNT(ws.website_session_id), 2) AS conv_rate_pct
FROM website_sessions ws
LEFT JOIN orders o 
       ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-27'
GROUP BY YEAR(ws.created_at), MONTH(ws.created_at);

-- -----------------------------------------------------------------------------
-- Q6: Full Landing Page Conversion Funnel Analysis (/home vs /lander-1)
-- Purpose: Identify step-by-step click-through rates across both funnels.
-- -----------------------------------------------------------------------------

WITH first_pageviews AS (
    -- Step 1: Identify the exact first pageview (entry point) for each session
    SELECT 
        ws.website_session_id,
        MIN(wp.website_pageview_id) AS lander_pageview_id
    FROM website_sessions ws
    JOIN website_pageviews wp 
        ON ws.website_session_id = wp.website_session_id
    WHERE ws.utm_source = 'gsearch'
      AND ws.utm_campaign = 'nonbrand'
      AND ws.created_at >= '2012-06-19'
      AND ws.created_at <  '2012-07-28'
    GROUP BY ws.website_session_id
),
session_landing_pages AS (
    -- Step 2: Map those entry pageviews specifically to /home or /lander-1
    SELECT 
        fp.website_session_id,
        fp.lander_pageview_id,
        wp.pageview_url AS landing_page
    FROM first_pageviews fp
    JOIN website_pageviews wp 
        ON fp.lander_pageview_id = wp.website_pageview_id
    WHERE wp.pageview_url IN ('/home', '/lander-1')
),
session_funnel_flags AS (
    -- Step 3: Evaluate forward-moving funnel step progression per session
    SELECT 
        slp.website_session_id,
        slp.landing_page,
        MAX(CASE WHEN wp.pageview_url = '/products'               THEN 1 ELSE 0 END) AS products_made_it,
        MAX(CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END) AS mrfuzzy_made_it,
        MAX(CASE WHEN wp.pageview_url = '/cart'                   THEN 1 ELSE 0 END) AS cart_made_it,
        MAX(CASE WHEN wp.pageview_url = '/shipping'               THEN 1 ELSE 0 END) AS shipping_made_it,
        MAX(CASE WHEN wp.pageview_url = '/billing'                THEN 1 ELSE 0 END) AS billing_made_it,
        MAX(CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS thank_you_made_it
    FROM session_landing_pages slp
    LEFT JOIN website_pageviews wp
        ON slp.website_session_id = wp.website_session_id
       AND wp.website_pageview_id > slp.lander_pageview_id  -- Enforces strict chronological order
    GROUP BY slp.website_session_id, slp.landing_page
)

-- Step 4: Aggregate volumes and compute step-by-step CTRs side-by-side
SELECT 
    landing_page,
    COUNT(DISTINCT website_session_id)                                         AS lander_sessions,
    COUNT(DISTINCT CASE WHEN products_made_it = 1  THEN website_session_id END) AS products_sessions,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1   THEN website_session_id END) AS mrfuzzy_sessions,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1      THEN website_session_id END) AS cart_sessions,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1  THEN website_session_id END) AS shipping_sessions,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1   THEN website_session_id END) AS billing_sessions,
    COUNT(DISTINCT CASE WHEN thank_you_made_it = 1 THEN website_session_id END) AS thank_you_sessions,

    -- Step-by-Step Click-Through Rates (CTR)
    COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id END) 
        * 1.0 / COUNT(DISTINCT website_session_id)                             AS lander_ctr,
        
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id END) 
        * 1.0 / NULLIF(COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id END), 0) AS products_ctr,
        
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id END) 
        * 1.0 / NULLIF(COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id END), 0) AS mrfuzzy_ctr,
        
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id END) 
        * 1.0 / NULLIF(COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id END), 0) AS cart_ctr,
        
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id END) 
        * 1.0 / NULLIF(COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id END), 0) AS shipping_ctr,
        
    COUNT(DISTINCT CASE WHEN thank_you_made_it = 1 THEN website_session_id END) 
        * 1.0 / NULLIF(COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id END), 0) AS billing_ctr

FROM session_funnel_flags
GROUP BY landing_page
ORDER BY landing_page DESC;



