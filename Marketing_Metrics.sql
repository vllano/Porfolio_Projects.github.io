-- This is a subscription based company that provides you the latest styles of clothing once a month for a monthly fee. 
-- They offer 2 tiers of pricing, the basic for $30 and Premium for $87. 
-- Here we will analyze their marketing appproach as well as user experience with their website & services.

-- Inspect the dataset
SELECT * FROM page_visits;

-- What is the company's purchase funnel?
SELECT DISTINCT page_name
FROM page_visits;

-- How many visitors make a purchase?
SELECT page_name, COUNT(DISTINCT user_id) AS user_count
FROM page_visits
GROUP BY page_name;

-- Calculate the conversion rates
WITH conversion AS(
	SELECT ROW_NUMBER()
    OVER(ORDER BY page_name) AS row_num, page_name, COUNT(DISTINCT user_id) AS user_count
	FROM page_visits
	GROUP BY page_name)
SELECT t1.page_name, t1.user_count, t1.user_count/t2.user_count AS conversion_rate
FROM conversion AS t1
LEFT JOIN conversion AS t2
	ON t1.row_num = (t2.row_num + 1);

-- How many campaigns and sources does this company use? What is the traffic for each campaign & source?
SELECT utm_source, utm_campaign, COUNT(user_id) AS traffic
FROM page_visits
GROUP BY 1,2;

-- How many first touches is each campaign responsible for?
WITH first_touch AS(
  SELECT user_id, MIN(timestamp) AS first_touch_at
  FROM page_visits
  GROUP BY user_id), -- Get user_id and the time of first touch
ft_attr AS (
  SELECT ft.user_id,
         ft.first_touch_at,
         pv.utm_source,
         pv.utm_campaign
  FROM first_touch AS ft
  JOIN page_visits AS pv
    ON ft.user_id = pv.user_id
    AND ft.first_touch_at = pv.timestamp) -- Get user_id & time of first touch combined w/ source & campaign for each
SELECT ft_attr.utm_source,
       ft_attr.utm_campaign,
       COUNT(*) AS first_touches
FROM ft_attr
GROUP BY 1, 2
ORDER BY 3 DESC; -- Count the results

-- How many last touches is each campaign responsible for?
WITH last_touch AS(
  SELECT user_id, MAX(timestamp) AS last_touch_at
  FROM page_visits
  GROUP BY user_id),-- Get user_id and the time of last touch
lt_attr AS (
  SELECT lt.user_id,
         lt.last_touch_at,
         pv.utm_source,
         pv.utm_campaign
  FROM last_touch AS lt
  JOIN page_visits AS pv
    ON lt.user_id = pv.user_id
    AND lt.last_touch_at = pv.timestamp) -- Get user_id and time of last touch combined w/ source & campaign for each
SELECT lt_attr.utm_source,
       lt_attr.utm_campaign,
       COUNT(*) AS last_touches
FROM lt_attr
GROUP BY 1, 2
ORDER BY 3 DESC; -- Count the results

-- How many last touches on the purchase page is each campaign responsible for?
WITH last_touch AS(
  SELECT user_id, MAX(timestamp) AS last_touch_at
  FROM page_visits
  WHERE page_name = '4 - purchase'
  GROUP BY user_id),-- get user_id and the time of last touch in the purchase page only
lt_attr AS (
  SELECT lt.user_id,
         lt.last_touch_at,
         pv.utm_source,
         pv.utm_campaign
  FROM last_touch AS lt
  JOIN page_visits AS pv
    ON lt.user_id = pv.user_id
    AND lt.last_touch_at = pv.timestamp) -- get user_id and time of last touch combined w/ source & campaign for each
SELECT lt_attr.utm_source,
       lt_attr.utm_campaign,
       COUNT(*) AS purchases
FROM lt_attr
GROUP BY 1, 2
ORDER BY 3 DESC;-- count the results

-- Once a customer purchases a subscription how long do they keep it for? Let calculate the churn rate the first 3 months of the year based on segment(87 or 30)
WITH months AS(
  SELECT
    '2017-01-01' AS first_day,
    '2017-01-31' AS last_day
  UNION
  SELECT
    '2017-02-01' AS first_day,
    '2017-02-31' AS last_day
  UNION
  SELECT
    '2017-03-01' AS first_day,
    '2017-03-31' AS last_day
),
cross_join AS(
  SELECT *
  FROM subscriptions
  CROSS JOIN months
),
status AS(
  SELECT id, first_day AS month,
    CASE
      WHEN (subscription_start < first_day)
        AND (subscription_end >= first_day
          OR subscription_end IS NULL)
          AND segment = 87 THEN 1
      ELSE 0
    END AS is_active_87,
    CASE
      WHEN (subscription_start < first_day)
        AND (subscription_end >= first_day
          OR subscription_end IS NULL)
          AND segment = 30 THEN 1
      ELSE 0
    END AS is_active_30,
    CASE
      WHEN (subscription_end BETWEEN first_day AND last_day)
        AND segment = 87 THEN 1
      ELSE 0
    END AS is_canceled_87,
    CASE
      WHEN (subscription_end BETWEEN first_day AND last_day)
        AND segment = 30 THEN 1
      ELSE 0
    END AS is_canceled_30
  FROM cross_join
), 
status_aggregate AS(
  SELECT month, 
  SUM(is_active_87) AS sum_active_87, 
  SUM(is_active_30) AS sum_active_30, 
  SUM(is_canceled_87) AS sum_canceled_87, 
  SUM(is_canceled_30) AS sum_canceled_30 
  FROM status 
  GROUP BY month
)
SELECT SUM(sum_canceled_87)/SUM(sum_active_87) AS churn_rate_87, SUM(sum_canceled_30)/SUM(sum_active_30) ASchurn_rate_30
FROM status_aggregate;


