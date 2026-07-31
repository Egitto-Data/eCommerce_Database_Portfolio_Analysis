/*==============================================================
Purpose:
Analyze website session performance, traffic acquisition,
conversion rates, and device trends for marketing campaigns.
==============================================================*/

-- ============================================================
-- Query 1
-- Purpose:
-- Compare marketing campaign performance by sessions,
-- orders, and conversion rate.
-- ============================================================

SELECT
    utm_source,
    utm_campaign,
    COUNT(ws.website_session_id)  AS total_sessions,
    COUNT(o.order_id) AS total_orders,
    CONCAT(
        ROUND(100 * COUNT(o.order_id) / COUNT(ws.website_session_id), 2),
        '%'
    )  AS cvr
FROM website_sessions AS ws
LEFT JOIN orders AS o USING (website_session_id)
GROUP BY
    utm_source,
    utm_campaign
ORDER BY total_sessions DESC;


-- ============================================================
-- Query 2
-- Purpose:
-- Summarize traffic sources before the analysis cutoff date.
-- ============================================================

SELECT
    utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS number_of_sessions
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY
    utm_source,
    utm_campaign,
    http_referer
ORDER BY number_of_sessions DESC;


-- ============================================================
-- Query 3
-- Purpose:
-- Calculate the conversion rate for GSearch nonbrand traffic.
-- ============================================================

SELECT
    COUNT(DISTINCT s.website_session_id)  AS total_sessions,
    COUNT(DISTINCT o.order_id)  AS total_orders,
    CONCAT(
        ROUND(
            COUNT(DISTINCT o.order_id) * 100.0
            / COUNT(DISTINCT s.website_session_id),
            2
        ),
        '%'
    )    AS session_to_order_conversion_rate
FROM website_sessions AS s
LEFT JOIN orders AS o
       ON s.website_session_id = o.website_session_id
WHERE s.created_at   < '2012-04-14'
  AND s.utm_source   = 'gsearch'
  AND s.utm_campaign = 'nonbrand';


-- ============================================================
-- Query 4
-- Purpose:
-- Track weekly session volume for GSearch nonbrand traffic.
-- ============================================================

SELECT
    MIN(DATE(created_at))   AS week_start_date,
    COUNT(DISTINCT website_session_id)   AS sessions
FROM website_sessions
WHERE created_at   < '2012-05-10'
  AND utm_source   = 'gsearch'
  AND utm_campaign = 'nonbrand'
GROUP BY
    YEAR(created_at),
    WEEK(created_at)
ORDER BY week_start_date;


-- ============================================================
-- Query 5
-- Purpose:
-- Compare desktop and mobile conversion performance.
-- ============================================================

SELECT
    s.device_type,
    COUNT(DISTINCT s.website_session_id)  AS total_sessions,
    COUNT(DISTINCT o.order_id)   AS total_orders,
    CONCAT(
        ROUND(
            COUNT(DISTINCT o.order_id) * 100.0
            / COUNT(DISTINCT s.website_session_id),
            2
        ),
        '%'
    )  AS session_to_order_conversion_rate
FROM website_sessions AS s
LEFT JOIN orders AS o
       ON s.website_session_id = o.website_session_id
WHERE s.created_at   < '2012-05-11'
  AND s.utm_source   = 'gsearch'
  AND s.utm_campaign = 'nonbrand'
GROUP BY
    s.device_type;


-- ============================================================
-- Query 6
-- Purpose:
-- Track weekly desktop and mobile session trends.
-- ============================================================

SELECT
    MIN(DATE(created_at))    AS week_start_date,
    COUNT(
        DISTINCT CASE
            WHEN device_type = 'desktop'
            THEN website_session_id
        END
    )                       AS desktop_sessions,
    COUNT(
        DISTINCT CASE
            WHEN device_type = 'mobile'
            THEN website_session_id
        END
    )      AS mobile_sessions
FROM website_sessions
WHERE created_at >= '2012-04-15'
  AND created_at <  '2012-06-19'
  AND utm_source   = 'gsearch'
  AND utm_campaign = 'nonbrand'
GROUP BY
    YEAR(created_at),
    WEEK(created_at)
ORDER BY week_start_date ;

