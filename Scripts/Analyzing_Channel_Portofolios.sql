/* =============================================================================
   EXPANDED CHANNEL PORTFOLIO ANALYSIS: GSEARCH VS. BSEARCH (NONBRAND)
   
   Purpose: 
     Pull weekly trended session volumes for gsearch nonbrand vs. bsearch nonbrand
     from August 2, 2012 up to November 29, 2012 to evaluate channel importance.
   ============================================================================= */

SELECT 
    MIN(DATE(created_at))                                                               AS week_start_date,
    COUNT(CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(CASE WHEN utm_source = 'bsearch'  THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE created_at > '2012-08-22' 
  AND created_at < '2012-11-29'
  AND utm_campaign = 'nonbrand'
GROUP BY YEARWEEK(created_at);

/* =============================================================================
   CHANNEL CHARACTERISTICS COMPARISON: MOBILE TRAFFIC SHARE (GSEARCH VS. BSEARCH)
   
   Purpose: 
     Compare mobile traffic composition (% mobile) between GSearch Nonbrand 
     and BSearch Nonbrand from 2012-08-22 to 2012-11-30 to inform mobile bidding 
     and landing page strategies.
   ============================================================================= */

SELECT 
    utm_source,
    COUNT(website_session_id)                                          AS sessions,
    COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions,
    ROUND(
        COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) * 100.0 / 
        NULLIF(COUNT(website_session_id), 0), 2
    )                                                                  AS pct_mobile
FROM website_sessions
WHERE created_at > '2012-08-22' 
  AND created_at < '2012-11-30'
  AND utm_campaign = 'nonbrand'
  AND utm_source IN ('gsearch', 'bsearch')
GROUP BY utm_source;

/* =============================================================================
   CROSS-CHANNEL BID OPTIMIZATION: GSEARCH VS. BSEARCH CONVERSION BY DEVICE
   
   Purpose: 
     Compare session-to-order conversion rates across GSearch and BSearch Nonbrand
     campaigns, segmented by device type (Desktop vs. Mobile) between 2012-08-22 
     and 2012-09-19 to guide bid reductions.
   ============================================================================= */

SELECT 
    ws.device_type,
    ws.utm_source,
    COUNT(ws.website_session_id)                                       AS sessions,
    COUNT(o.order_id)                                                  AS orders,
    ROUND(COUNT(o.order_id) * 100.0 / NULLIF(COUNT(ws.website_session_id), 0), 2) AS conv_rate_pct
FROM website_sessions ws
LEFT JOIN orders o 
       ON ws.website_session_id = o.website_session_id
WHERE ws.created_at >= '2012-08-22' 
  AND ws.created_at < '2012-09-19'
  AND ws.utm_campaign = 'nonbrand'
  AND ws.utm_source IN ('gsearch', 'bsearch')
GROUP BY 
    ws.device_type,
    ws.utm_source;
	
/* =============================================================================
   CHANNEL PORTFOLIO TRENDS: GSEARCH VS. BSEARCH BY DEVICE TYPE
   
   Purpose: 
     Evaluate the impact of BSearch bid reductions (made on Dec 2, 2012) by 
     tracking weekly session volumes and BSearch-to-GSearch volume ratios 
     for Desktop and Mobile Nonbrand traffic between 2012-11-04 and 2012-12-22.
   ============================================================================= */

SELECT 
    MIN(DATE(created_at))                                              AS week_start_date,
    COUNT(CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id END) AS g_desktop_sessions,
    COUNT(CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id END) AS b_desktop_sessions,
    ROUND(
        COUNT(CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id END), 0), 2
    )                                                                  AS b_pct_of_g_desktop,
    COUNT(CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile'  THEN website_session_id END) AS g_mobile_sessions,
    COUNT(CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile'  THEN website_session_id END) AS b_mobile_sessions,
    ROUND(
        COUNT(CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile'  THEN website_session_id END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile'  THEN website_session_id END), 0), 2
    )                                                                  AS b_pct_of_g_mobile
FROM website_sessions
WHERE created_at >= '2012-11-04' 
  AND created_at < '2012-12-22'
  AND utm_campaign = 'nonbrand'
  AND utm_source IN ('gsearch', 'bsearch')
GROUP BY YEARWEEK(created_at);

/* =============================================================================
   ANALYZING FREE & DIRECT CHANNELS: ORGANIC, DIRECT, AND PAID BRAND LIFT
   
   Purpose: 
     Track monthly session trends and traffic share (% of Paid Nonbrand) for 
     Direct Type-in, Organic Search, and Paid Brand channels prior to Dec 23, 2012 
     to demonstrate brand growth momentum for investors.
   ============================================================================= */

WITH categorized_sessions AS (
    SELECT 
        website_session_id,
        created_at,
        CASE 
            WHEN utm_source IS NULL AND http_referer IS NULL 
                THEN 'direct_type_in'
            WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') 
                THEN 'organic_search'
            WHEN utm_campaign = 'nonbrand' 
                THEN 'paid_nonbrand'
            WHEN utm_campaign = 'brand'    
                THEN 'paid_brand'
            ELSE 'other'
        END AS channel_group
    FROM website_sessions
    WHERE created_at < '2012-12-23'
)
SELECT 
    YEAR(created_at)                                                    AS yr,
    MONTH(created_at)                                                   AS mo,
    COUNT(CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END) AS nonbrand_sessions,
    COUNT(CASE WHEN channel_group = 'paid_brand'    THEN website_session_id END) AS brand_sessions,
    ROUND(
        COUNT(CASE WHEN channel_group = 'paid_brand' THEN website_session_id END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END), 0), 2
    )                                                                   AS brand_pct_of_nonbrand,
    COUNT(CASE WHEN channel_group = 'direct_type_in' THEN website_session_id END) AS direct_sessions,
    ROUND(
        COUNT(CASE WHEN channel_group = 'direct_type_in' THEN website_session_id END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END), 0), 2
    )                                                                   AS direct_pct_of_nonbrand,
    COUNT(CASE WHEN channel_group = 'organic_search' THEN website_session_id END) AS organic_sessions,
    ROUND(
        COUNT(CASE WHEN channel_group = 'organic_search' THEN website_session_id END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END), 0), 2
    )                                                                   AS organic_pct_of_nonbrand
FROM categorized_sessions
GROUP BY 
    YEAR(created_at),
    MONTH(created_at)
ORDER BY 
    yr, 
    mo;