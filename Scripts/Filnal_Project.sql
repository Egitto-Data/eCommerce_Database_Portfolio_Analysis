/* =============================================================================
   MAVEN FUZZY FACTORY — MASTER ANALYTICS REPOSITORY
   -----------------------------------------------------------------------------
   Author:        Data Engineering & Analytics Team
   Database:      Maven Fuzzy Factory (MySQL / Snowflake / BigQuery / Redshift)
   Description:   Comprehensive executive reporting suite tracking volume growth,
                  channel efficiency, product performance, A/B test variants, 
                  customer lifetime value (CLV), and monthly refund rates.
   
   TABLE OF CONTENTS:
     1. Executive Quarterly Growth (Sessions & Orders)
     2. Quarterly Efficiency Metrics (Conversion Rate, AOV, RPS)
     3. Quarterly Channel Breakdown (Order Volumes)
     4. Quarterly Channel Efficiency (Conversion Rates by Source)
     5. Monthly Product Revenue, Margins & Seasonality
     6. Billing Page A/B Test Conversion Rate Analysis (/billing vs /billing-2)
     7. Customer Lifetime Value (CLV) by First Acquisition Channel
     8. Monthly Product Refund Rates (Quality & Supplier Monitoring)
   ============================================================================= */


-- =============================================================================
-- 1. EXECUTIVE QUARTERLY VOLUME GROWTH
-- Business Objective:
--   Track top-line business growth by aggregating unique session volume and 
--   completed customer orders on a quarterly cadence across company history.
-- =============================================================================

SELECT 
    YEAR(ws.created_at)                 AS yr,
    QUARTER(ws.created_at)              AS qtr,
    COUNT(DISTINCT ws.website_session_id) AS total_sessions,
    COUNT(DISTINCT o.order_id)          AS total_orders
FROM website_sessions ws
LEFT JOIN orders o 
    ON ws.website_session_id = o.website_session_id
GROUP BY 1, 2
ORDER BY 1, 2;


-- =============================================================================
-- 2. QUARTERLY EFFICIENCY METRICS
-- Business Objective:
--   Measure core platform economic and operational efficiency over time:
--     - Session-to-Order Conversion Rate (Conversion Efficiency)
--     - Average Order Value (AOV / Revenue per Order)
--     - Revenue per Session (RPS / Paid Marketing Bidding Ceiling)
-- =============================================================================

SELECT 
    YEAR(ws.created_at)    AS yr,
    QUARTER(ws.created_at) AS qtr,
    
    -- Session-to-Order Conversion Rate (%)
    COUNT(DISTINCT o.order_id) * 1.0 
        / COUNT(DISTINCT ws.website_session_id)             AS session_to_order_conv_rate,
        
    -- Average Order Value / Revenue per Order ($)
    SUM(o.price_usd) 
        / NULLIF(COUNT(DISTINCT o.order_id), 0)             AS revenue_per_order,
    
    -- Revenue per Session / Blended RPS ($)
    SUM(o.price_usd) 
        / COUNT(DISTINCT ws.website_session_id)             AS revenue_per_session

FROM website_sessions ws
LEFT JOIN orders o 
    ON ws.website_session_id = o.website_session_id
GROUP BY 1, 2
ORDER BY 1, 2;


-- =============================================================================
-- 3. QUARTERLY ORDER VOLUME BY ACQUISITION CHANNEL
-- Business Objective:
--   Break down quarterly order volume across distinct traffic streams to evaluate
--   acquisition channel reliance (Paid Search vs. Organic vs. Direct).
-- =============================================================================

SELECT 
    YEAR(ws.created_at)    AS yr,
    QUARTER(ws.created_at) AS qtr,
    
    -- Paid Search Non-Brand Orders
    COUNT(DISTINCT CASE WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' THEN o.order_id END) AS gsearch_nonbrand_orders,
    COUNT(DISTINCT CASE WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand' THEN o.order_id END) AS bsearch_nonbrand_orders,
    
    -- Paid Search Brand Orders
    COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand'                                   THEN o.order_id END) AS brand_search_orders,
    
    -- Earned & Direct Traffic Orders
    COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NOT NULL     THEN o.order_id END) AS organic_search_orders,
    COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL         THEN o.order_id END) AS direct_typein_orders

FROM website_sessions ws
LEFT JOIN orders o 
    ON ws.website_session_id = o.website_session_id
GROUP BY 1, 2
ORDER BY 1, 2;


-- =============================================================================
-- 4. QUARTERLY CONVERSION RATES BY ACQUISITION CHANNEL
-- Business Objective:
--   Measure how efficiently each acquisition channel converts raw session traffic 
--   into completed orders over time, isolating performance optimizations.
-- =============================================================================

SELECT 
    YEAR(ws.created_at)    AS yr,
    QUARTER(ws.created_at) AS qtr,
    
    -- Gsearch Nonbrand Conversion Rate
    COUNT(DISTINCT CASE WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' THEN o.order_id END) * 1.0 
        / NULLIF(COUNT(DISTINCT CASE WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' THEN ws.website_session_id END), 0) AS gsearch_nonbrand_conv_rate,
        
    -- Bsearch Nonbrand Conversion Rate
    COUNT(DISTINCT CASE WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand' THEN o.order_id END) * 1.0 
        / NULLIF(COUNT(DISTINCT CASE WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand' THEN ws.website_session_id END), 0) AS bsearch_nonbrand_conv_rate,
        
    -- Brand Search Conversion Rate
    COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN o.order_id END) * 1.0 
        / NULLIF(COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN ws.website_session_id END), 0) AS brand_conv_rate,
        
    -- Organic Search Conversion Rate
    COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NOT NULL THEN o.order_id END) * 1.0 
        / NULLIF(COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NOT NULL THEN ws.website_session_id END), 0) AS organic_conv_rate,
        
    -- Direct Type-in Conversion Rate
    COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL THEN o.order_id END) * 1.0 
        / NULLIF(COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL THEN ws.website_session_id END), 0) AS direct_conv_rate

FROM website_sessions ws
LEFT JOIN orders o 
    ON ws.website_session_id = o.website_session_id
GROUP BY 1, 2
ORDER BY 1, 2;


-- =============================================================================
-- 5. MONTHLY REVENUE & MARGIN BY PRODUCT (SEASONALITY ANALYSIS)
-- Business Objective:
--   Break down monthly gross sales revenue and gross profit margin by individual
--   product ID to evaluate portfolio expansion and seasonal holiday spikes.
-- =============================================================================

SELECT 
    YEAR(created_at)  AS yr,
    MONTH(created_at) AS mo,
    
    -- Product 1: Mr. Fuzzy
    SUM(CASE WHEN product_id = 1 THEN price_usd             ELSE 0 END) AS mrfuzzy_revenue,
    SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd  ELSE 0 END) AS mrfuzzy_margin,
    
    -- Product 2: Love Bear
    SUM(CASE WHEN product_id = 2 THEN price_usd             ELSE 0 END) AS lovebear_revenue,
    SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd  ELSE 0 END) AS lovebear_margin,
    
    -- Product 3: Birthday Sugarbear
    SUM(CASE WHEN product_id = 3 THEN price_usd             ELSE 0 END) AS sugarbear_revenue,
    SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd  ELSE 0 END) AS sugarbear_margin,
    
    -- Product 4: Mini Bear
    SUM(CASE WHEN product_id = 4 THEN price_usd             ELSE 0 END) AS minibear_revenue,
    SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd  ELSE 0 END) AS minibear_margin,
    
    -- Overall Monthly Portfolio Totals
    SUM(price_usd)                                                      AS total_revenue,
    SUM(price_usd - cogs_usd)                                           AS total_margin

FROM order_items
GROUP BY 1, 2
ORDER BY 1, 2;


-- =============================================================================
-- 6. BILLING PAGE A/B TEST CONVERSION RATE ANALYSIS
-- Business Objective:
--   Compare session volumes, order counts, and billing-to-order conversion rates 
--   between the original `/billing` page and the new `/billing-2` test page.
-- =============================================================================

SELECT 
    wp.pageview_url                                                  AS billing_version_seen,
    
    -- Session & Order Counts
    COUNT(DISTINCT wp.website_session_id)                            AS billing_sessions,
    COUNT(DISTINCT o.order_id)                                       AS orders,
    
    -- Billing-to-Order Conversion Rate
    COUNT(DISTINCT o.order_id) * 1.0 
        / COUNT(DISTINCT wp.website_session_id)                      AS billing_to_order_rate

FROM website_pageviews wp
LEFT JOIN orders o 
    ON wp.website_session_id = o.website_session_id

WHERE wp.pageview_url IN ('/billing', '/billing-2')
  AND wp.created_at < '2012-11-10'
  AND wp.website_pageview_id >= (
      -- Dynamically anchors test launch date based on first /billing-2 debut
      SELECT MIN(website_pageview_id) 
      FROM website_pageviews 
      WHERE pageview_url = '/billing-2'
  )

GROUP BY wp.pageview_url
ORDER BY billing_version_seen ASC;


-- =============================================================================
-- 7. CUSTOMER LIFETIME VALUE (CLV) BY FIRST ACQUISITION CHANNEL
-- Business Objective:
--   Determine the long-term monetary value (lifetime orders, revenue, and margins)
--   generated by users based on their initial acquisition channel.
-- =============================================================================

WITH user_first_channel AS (
    SELECT 
        ws.user_id,
        FIRST_VALUE(
            CASE 
                WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' THEN 'Gsearch Nonbrand'
                WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand' THEN 'Bsearch Nonbrand'
                WHEN ws.utm_campaign = 'brand'                                THEN 'Brand Search'
                WHEN ws.utm_source IS NULL AND ws.http_referer IS NOT NULL    THEN 'Organic Search'
                WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL        THEN 'Direct Type-In'
                ELSE 'Other Paid/Referral'
            END
        ) OVER (
            PARTITION BY ws.user_id 
            ORDER BY ws.website_session_id ASC
        ) AS acquisition_channel
    FROM website_sessions ws
)

SELECT 
    ufc.acquisition_channel,
    COUNT(DISTINCT ufc.user_id)                             AS total_acquired_users,
    COUNT(DISTINCT o.order_id)                              AS total_lifetime_orders,
    SUM(oi.price_usd)                                       AS total_lifetime_revenue,
    SUM(oi.price_usd - oi.cogs_usd)                         AS total_lifetime_margin,
    SUM(oi.price_usd) / COUNT(DISTINCT ufc.user_id)         AS average_clv_revenue,
    SUM(oi.price_usd - oi.cogs_usd) / COUNT(DISTINCT ufc.user_id) AS average_clv_margin

FROM user_first_channel ufc
JOIN orders o 
    ON ufc.user_id = o.user_id
JOIN order_items oi 
    ON o.order_id = oi.order_id

GROUP BY ufc.acquisition_channel
ORDER BY average_clv_margin DESC;


-- =============================================================================
-- 8. MONTHLY PRODUCT REFUND RATES (QUALITY & SUPPLIER MONITORING)
-- Business Objective:
--   Track order item volume and refund rates across Products 1 through 4 to confirm
--   whether historical quality and supplier issues on Product 1 (Mr. Fuzzy) are resolved.
-- =============================================================================

SELECT 
    YEAR(oi.created_at)                                                 AS yr,
    MONTH(oi.created_at)                                                AS mo,
    
    -- Product 1: Mr. Fuzzy
    COUNT(CASE WHEN oi.product_id = 1 THEN oi.order_item_id END)        AS p1_orders,
    COUNT(CASE WHEN oi.product_id = 1 THEN oir.order_item_id END) * 1.0
        / NULLIF(COUNT(CASE WHEN oi.product_id = 1 THEN oi.order_item_id END), 0) AS p1_refund_rate,
        
    -- Product 2: Love Bear
    COUNT(CASE WHEN oi.product_id = 2 THEN oi.order_item_id END)        AS p2_orders,
    COUNT(CASE WHEN oi.product_id = 2 THEN oir.order_item_id END) * 1.0
        / NULLIF(COUNT(CASE WHEN oi.product_id = 2 THEN oi.order_item_id END), 0) AS p2_refund_rate,
        
    -- Product 3: Birthday Sugarbear
    COUNT(CASE WHEN oi.product_id = 3 THEN oi.order_item_id END)        AS p3_orders,
    COUNT(CASE WHEN oi.product_id = 3 THEN oir.order_item_id END) * 1.0
        / NULLIF(COUNT(CASE WHEN oi.product_id = 3 THEN oi.order_item_id END), 0) AS p3_refund_rate,
        
    -- Product 4: Mini Bear
    COUNT(CASE WHEN oi.product_id = 4 THEN oi.order_item_id END)        AS p4_orders,
    COUNT(CASE WHEN oi.product_id = 4 THEN oir.order_item_id END) * 1.0
        / NULLIF(COUNT(CASE WHEN oi.product_id = 4 THEN oi.order_item_id END), 0) AS p4_refund_rate

FROM order_items oi
LEFT JOIN order_item_refunds oir 
    ON oi.order_item_id = oir.order_item_id
WHERE oi.created_at < '2014-10-15'
GROUP BY 1, 2
ORDER BY 1, 2;
