-- PIZZA RUNNER: A. Pizza Metrics

-- 1. How many pizzas were ordered?
SELECT COUNT(*) FROM pizza_runner.customer_orders

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) FROM pizza_runner.customer_orders

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id,COUNT(DISTINCT order_id) AS orders_delivered
FROM pizza_runner.runner_orders
WHERE pickup_time IS NOT NULL
GROUP BY runner_id

-- 4. How many of each type of pizza was delivered?
SELECT pizza_name,
COUNT(customer_orders.order_id) AS pizzas_delivered
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.pizza_names 
ON customer_orders.pizza_id=pizza_names.pizza_id
INNER JOIN pizza_runner.runner_orders
ON customer_orders.order_id=runner_orders.order_id
WHERE pickup_time<>'null'
GROUP BY pizza_name

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT pizza_name,
COUNT(customer_orders.order_id) AS pizzas_delivered
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.pizza_names 
ON customer_orders.pizza_id=pizza_names.pizza_id
INNER JOIN pizza_runner.runner_orders
ON customer_orders.order_id=runner_orders.order_id
WHERE pickup_time<>'null'
GROUP BY pizza_name

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT customer_orders.order_id,COUNT(customer_orders.pizza_id) AS pizzas_ordered
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.pizza_names 
ON customer_orders.pizza_id=pizza_names.pizza_id
INNER JOIN pizza_runner.runner_orders
ON customer_orders.order_id=runner_orders.order_id
WHERE pickup_time<>'null'
GROUP BY customer_orders.order_id
ORDER BY pizzas_ordered DESC
LIMIT 1

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
  customer_id, 
  SUM(CASE 
    WHEN 
        (
          (exclusions IS NOT NULL AND exclusions<>'null' AND LENGTH(exclusions)>0) 
        AND (extras IS NOT NULL AND extras<>'null' AND LENGTH(extras)>0)
        )=TRUE
    THEN 1 
    ELSE 0
  END) as changes, 
  SUM(CASE 
    WHEN 
        (
          (exclusions IS NOT NULL AND exclusions<>'null' AND LENGTH(exclusions)>0) 
        AND (extras IS NOT NULL AND extras<>'null' AND LENGTH(extras)>0)
        )=TRUE
    THEN 0 
    ELSE 1
  END) as no_changes 
FROM 
  pizza_runner.customer_orders as co 
  INNER JOIN pizza_runner.runner_orders as ro on ro.order_id = co.order_id 
WHERE 
  pickup_time<>'null'
GROUP BY 
  customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT 
COUNT(co.pizza_id) as pizzas_delivered_with_exclusions_and_extras 
FROM 
  pizza_runner.customer_orders as co 
  INNER JOIN pizza_runner.runner_orders as ro on ro.order_id = co.order_id 
WHERE 
  pickup_time<>'null'
  AND (exclusions IS NOT NULL AND exclusions<>'null' AND LENGTH(exclusions)>0) 
  AND (extras IS NOT NULL AND extras<>'null' AND LENGTH(extras)>0);

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
DATE_PART('hour', order_time) as hour_of_day, 
COUNT(*) as pizzas_ordered
FROM 
pizza_runner.customer_orders 
GROUP BY hour_of_day
ORDER BY hour_of_day

-- 10. What was the volume of orders for each day of the week?
SELECT 
TO_CHAR(order_time, 'Day') as day_of_week, 
COUNT(*) as pizzas_ordered
FROM pizza_runner.customer_orders 
GROUP BY day_of_week
