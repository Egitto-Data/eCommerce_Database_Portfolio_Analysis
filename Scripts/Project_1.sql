/* =============================================================================
   PROJECT-1 E-COMMERCE PERFORMANCE ANALYSIS & AB TESTING EVALUATION
   
   Purpose: 
     Comprehensive analytical suite evaluating website traffic volume, acquisition 
     channels, funnel conversion rates, and the financial impact of A/B tests 
     (custom landing pages & billing page optimization) prior to 2012-11-27.
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
WITH funnel_flags AS (
    SELECT 
        ws.website_session_id,
        MAX(CASE WHEN wpv.pageview_url = '/home'                      THEN 1 ELSE 0 END) AS saw_home,
        MAX(CASE WHEN wpv.pageview_url = '/lander-1'                  THEN 1 ELSE 0 END) AS saw_lander,
        MAX(CASE WHEN wpv.pageview_url = '/products'                  THEN 1 ELSE 0 END) AS saw_products,
        MAX(CASE WHEN wpv.pageview_url = '/the-original-mr-fuzzy'     THEN 1 ELSE 0 END) AS saw_mrfuzzy,
        MAX(CASE WHEN wpv.pageview_url = '/cart'                      THEN 1 ELSE 0 END) AS saw_cart,
        MAX(CASE WHEN wpv.pageview_url = '/shipping'                  THEN 1 ELSE 0 END) AS saw_shipping,
        MAX(CASE WHEN wpv.pageview_url = '/billing'                   THEN 1 ELSE 0 END) AS saw_billing,
        MAX(CASE WHEN wpv.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS saw_thankyou
    FROM website_sessions ws
    INNER JOIN website_pageviews wpv 
            ON ws.website_session_id = wpv.website_session_id
    WHERE ws.created_at >= '2012-06-19' AND ws.created_at <= '2012-07-28'
      AND ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand'
    GROUP BY ws.website_session_id
)
SELECT 
    CASE 
        WHEN saw_home = 1   THEN '/home'
        WHEN saw_lander = 1 THEN '/lander-1'
    END                                                                AS landing_page,
    COUNT(website_session_id)                                          AS total_sessions,
    SUM(saw_products)                                                  AS to_products,
    SUM(saw_mrfuzzy)                                                   AS to_mrfuzzy,
    SUM(saw_cart)                                                      AS to_cart,
    SUM(saw_shipping)                                                  AS to_shipping,
    SUM(saw_billing)                                                   AS to_billing,
    SUM(saw_thankyou)                                                  AS to_thankyou,
    ROUND(SUM(saw_products) * 100.0 / COUNT(website_session_id), 1)    AS lander_click_rate_pct,
    ROUND(SUM(saw_mrfuzzy)  * 100.0 / NULLIF(SUM(saw_products), 0), 1) AS products_click_rate_pct,
    ROUND(SUM(saw_cart)     * 100.0 / NULLIF(SUM(saw_mrfuzzy), 0), 1)  AS mrfuzzy_click_rate_pct,
    ROUND(SUM(saw_shipping) * 100.0 / NULLIF(SUM(saw_cart), 0), 1)     AS cart_click_rate_pct,
    ROUND(SUM(saw_billing)  * 100.0 / NULLIF(SUM(saw_shipping), 0), 1)  AS shipping_click_rate_pct,
    ROUND(SUM(saw_thankyou) * 100.0 / NULLIF(SUM(saw_billing), 0), 1)   AS billing_click_rate_pct
FROM funnel_flags
WHERE saw_home = 1 OR saw_lander = 1
GROUP BY 1;


-- -----------------------------------------------------------------------------
-- Q7: Billing Page A/B Test Revenue Lift (/billing vs /billing-2)
-- Purpose: Calculate Revenue Per Billing Page Visit lift and monthly impact.
-- -----------------------------------------------------------------------------
WITH test_sessions AS (
    SELECT 
        wpv.website_session_id,
        wpv.pageview_url                                               AS billing_version,
        o.order_id,
        o.price_usd
    FROM website_pageviews wpv
    LEFT JOIN orders o 
           ON wpv.website_session_id = o.website_session_id
    WHERE wpv.created_at >= '2012-09-10' AND wpv.created_at < '2012-11-10'
      AND wpv.pageview_url IN ('/billing', '/billing-2')
),
billing_metrics AS (
    SELECT 
        billing_version,
        COUNT(website_session_id)                                      AS sessions,
        SUM(price_usd)                                                 AS total_revenue,
        SUM(price_usd) / COUNT(website_session_id)                     AS rev_per_page
    FROM test_sessions
    GROUP BY billing_version
),
past_month_billing AS (
    SELECT COUNT(website_session_id)                                   AS past_month_sessions
    FROM website_pageviews
    WHERE pageview_url IN ('/billing', '/billing-2')
      AND created_at BETWEEN '2012-10-27' AND '2012-11-27'
)
SELECT 
    p.past_month_sessions,
    MAX(CASE WHEN billing_version = '/billing'   THEN rev_per_page END) AS old_rev_per_page,
    MAX(CASE WHEN billing_version = '/billing-2' THEN rev_per_page END) AS new_rev_per_page,
    MAX(CASE WHEN billing_version = '/billing-2' THEN rev_per_page END) - 
    MAX(CASE WHEN billing_version = '/billing'   THEN rev_per_page END) AS lift_per_page,
    ROUND(p.past_month_sessions * (
        MAX(CASE WHEN billing_version = '/billing-2' THEN rev_per_page END) - 
        MAX(CASE WHEN billing_version = '/billing'   THEN rev_per_page END)
    ), 2)                                                              AS total_monthly_value
FROM billing_metrics, past_month_billing p
GROUP BY p.past_month_sessions;
