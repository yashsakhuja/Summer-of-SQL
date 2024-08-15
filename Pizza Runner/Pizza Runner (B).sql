-- PIZZA RUNNER: B. Runner and Customer Experience


-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
WITH week_start AS(
SELECT 
    runner_id, 
    registration_date, 
    DATE_TRUNC('week', registration_date) + INTERVAL '4 days' AS start_of_week 
FROM pizza_runner.runners
)
SELECT 
  start_of_week, 
  COUNT(runner_id) AS total_runner_signups
FROM 
  week_start 
GROUP BY 
  start_of_week 
ORDER BY 
  start_of_week;


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT 
    runner_id,
    AVG(EXTRACT(EPOCH FROM (CAST(pickup_time AS timestamp) - CAST(order_time AS timestamp))) / 60) AS avg_runner_pickup_time_minutes
FROM pizza_runner.runner_orders
INNER JOIN pizza_runner.customer_orders
    ON runner_orders.order_id = customer_orders.order_id
WHERE pickup_time <> 'null'
GROUP BY runner_id;


-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT 
    customer_orders.order_id,
    COUNT(pizza_id) AS pizzas_ordered,
    AVG(EXTRACT(EPOCH FROM (CAST(pickup_time AS timestamp) - CAST(order_time AS timestamp))) / 60) AS avg_prep_time_minutes
FROM pizza_runner.runner_orders
INNER JOIN pizza_runner.customer_orders
    ON runner_orders.order_id = customer_orders.order_id
WHERE pickup_time <> 'null'
GROUP BY customer_orders.order_id;


-- 4. What was the average distance travelled for each customer?
SELECT
    customer_id,
    AVG(CAST(REPLACE(distance, 'km', '') AS FLOAT)) AS avg_distance_covered
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.runner_orders
    ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.cancellation IS NULL
GROUP BY customer_id;


-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT
    MAX(REGEXP_REPLACE(runner_orders.duration, '[^0-9]', '', 'g')::int) - MIN(REGEXP_REPLACE(runner_orders.duration, '[^0-9]', '', 'g')::int) AS difference_in_time
FROM 
    pizza_runner.customer_orders
INNER JOIN 
    pizza_runner.runner_orders
    ON customer_orders.order_id = runner_orders.order_id
WHERE 
    runner_orders.cancellation IS NULL;


-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
runner_id,
order_id,
CAST(REPLACE(distance, 'km', '') AS FLOAT)/
CAST(REGEXP_REPLACE(runner_orders.duration, '[^0-9]', '', 'g') AS FLOAT) AS avg_speed
FROM pizza_runner.runner_orders
WHERE 
    runner_orders.cancellation IS NULL
ORDER BY runner_id,order_id


-- 7. What is the successful delivery percentage for each runner?
SELECT 
  runner_id, 
  COUNT(order_id) AS orders, 
  ROUND(
    100.0 * SUM(
      CASE 
          WHEN pickup_time = 'null' 
          THEN 0
          ELSE 1 
      END
    ) / COUNT(order_id), 
    1
  ) AS delivery_percentage 
FROM 
  pizza_runner.runner_orders 
GROUP BY 
  runner_id
ORDER BY delivery_percentage DESC
