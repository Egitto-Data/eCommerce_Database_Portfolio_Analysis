/* =============================================================================
   BUSINESS PATTERNS ANALYSIS: HOURLY SESSION VOLUME BY DAY OF WEEK
   
   Purpose: 
     Evaluate website session volume split by hour of day (0-23) and day of week 
     (Mon-Sun) between September 15, 2012, and November 15, 2012, to assist Cindy 
     in planning live chat support staffing capacity.
   ============================================================================= */

WITH daily_hourly_sessions AS (
    -- Step 1: Calculate total session volume per unique date, day of week, and hour
    SELECT 
        DATE(created_at)                                                AS session_date,
        WEEKDAY(created_at)                                             AS wkday, -- 0 = Monday, ..., 6 = Sunday
        HOUR(created_at)                                                AS hr,    -- 0 through 23
        COUNT(website_session_id)                                       AS website_sessions
    FROM website_sessions
    WHERE created_at >= '2012-09-15' 
      AND created_at < '2012-11-15'
    GROUP BY 
        DATE(created_at),
        WEEKDAY(created_at),
        HOUR(created_at)
)
-- Step 2: Aggregate daily hourly session averages into a Day-of-Week x Hour Matrix
SELECT 
    hr                                                                  AS hour_of_day,
    ROUND(AVG(CASE WHEN wkday = 0 THEN website_sessions ELSE NULL END), 1) AS mon,
    ROUND(AVG(CASE WHEN wkday = 1 THEN website_sessions ELSE NULL END), 1) AS tue,
    ROUND(AVG(CASE WHEN wkday = 2 THEN website_sessions ELSE NULL END), 1) AS wed,
    ROUND(AVG(CASE WHEN wkday = 3 THEN website_sessions ELSE NULL END), 1) AS thu,
    ROUND(AVG(CASE WHEN wkday = 4 THEN website_sessions ELSE NULL END), 1) AS fri,
    ROUND(AVG(CASE WHEN wkday = 5 THEN website_sessions ELSE NULL END), 1) AS sat,
    ROUND(AVG(CASE WHEN wkday = 6 THEN website_sessions ELSE NULL END), 1) AS sun
FROM daily_hourly_sessions
GROUP BY hr
ORDER BY hour_of_day ASC;

/* =============================================================================
   SEASONALITY ANALYSIS: MONTHLY TRENDING (2012)
   
   Purpose: 
     Evaluate monthly session and order volume patterns for 2012 up to 2013-01-01
     to establish baseline seasonal trends for executive planning.
   ============================================================================= */

SELECT 
    YEAR(ws.created_at)                                                 AS yr,
    MONTH(ws.created_at)                                                AS mo,
    COUNT(DISTINCT ws.website_session_id)                               AS sessions,
    COUNT(DISTINCT o.order_id)                                          AS orders
FROM website_sessions ws
LEFT JOIN orders o
       ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2013-01-01'
GROUP BY 
    YEAR(ws.created_at),
    MONTH(ws.created_at)
ORDER BY yr ASC, mo ASC;

/* =============================================================================
   SEASONALITY ANALYSIS: WEEKLY TRENDING (2012)
   
   Purpose: 
     Evaluate granular weekly session and order volumes for 2012 up to 2013-01-01
     to isolate major holiday surges (e.g., Black Friday & Cyber Monday).
   ============================================================================= */

SELECT 
    YEAR(ws.created_at)                                                 AS yr,
    WEEK(ws.created_at)                                                 AS wk,
    MIN(DATE(ws.created_at))                                            AS week_start_date,
    COUNT(DISTINCT ws.website_session_id)                               AS sessions,
    COUNT(DISTINCT o.order_id)                                          AS orders
FROM website_sessions ws
LEFT JOIN orders o
       ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2013-01-01'
GROUP BY 
    YEAR(ws.created_at),
    WEEK(ws.created_at)
ORDER BY yr ASC, wk ASC;