-- PIZZA RUNNER: C. Ingredient Optimisation

-- 1.  What are the standard ingredients for each pizza?
WITH expanded_toppings AS (
  SELECT 
    pizza_recipes.pizza_id,
    pizza_names.pizza_name,
    unnest(string_to_array(pizza_recipes.toppings, ','))::int AS topping_id
  FROM 
    pizza_runner.pizza_names
  INNER JOIN 
    pizza_runner.pizza_recipes
    ON pizza_names.pizza_id = pizza_recipes.pizza_id
)
SELECT 
  expanded_toppings.pizza_id,
  expanded_toppings.pizza_name,
  expanded_toppings.topping_id,
  pizza_toppings.topping_name
FROM 
  expanded_toppings
INNER JOIN 
  pizza_runner.pizza_toppings
  ON expanded_toppings.topping_id = pizza_toppings.topping_id
ORDER BY pizza_id,topping_id ASC;


-- 2. What was the most commonly added extra?
SELECT 
  topping_name,
  COUNT(extras_id) as extra_inclusions
FROM 
  pizza_runner.customer_orders
CROSS JOIN LATERAL (
  SELECT unnest(string_to_array(customer_orders.extras, ','))::int AS extras_id
) AS extras
INNER JOIN 
  pizza_runner.pizza_toppings
  ON extras.extras_id = pizza_toppings.topping_id
WHERE 
  customer_orders.extras <> 'null'
GROUP BY topping_name
ORDER BY extra_inclusions DESC
LIMIT 1;


-- 3. What was the most common exclusion?
SELECT 
  topping_name,
  COUNT(exclusions_id) as extra_exclusions
FROM 
  pizza_runner.customer_orders
CROSS JOIN LATERAL (
  SELECT unnest(string_to_array(customer_orders.exclusions, ','))::int AS exclusions_id
) AS exclusions
INNER JOIN 
  pizza_runner.pizza_toppings
  ON exclusions.exclusions_id = pizza_toppings.topping_id
WHERE 
  customer_orders.exclusions <> 'null'
GROUP BY topping_name
ORDER BY extra_exclusions DESC
LIMIT 1;


-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers"

WITH EXCLUSIONS AS (
    SELECT 
        co.order_id,
        co.pizza_id,
        exclusions.exclusions_id AS topping_id,
        t.topping_name
    FROM 
        pizza_runner.customer_orders AS co
    CROSS JOIN LATERAL (
        SELECT unnest(string_to_array(co.exclusions, ', '))::int AS exclusions_id
    ) AS exclusions
    INNER JOIN pizza_runner.pizza_toppings AS t ON t.topping_id = exclusions.exclusions_id
    WHERE co.exclusions <> 'null'
),
EXTRAS AS (
    SELECT 
        co.order_id,
        co.pizza_id,
        extras.extras_id AS topping_id,
        t.topping_name
    FROM 
        pizza_runner.customer_orders AS co
    CROSS JOIN LATERAL (
        SELECT unnest(string_to_array(co.extras, ', '))::int AS extras_id
    ) AS extras
    INNER JOIN pizza_runner.pizza_toppings AS t ON t.topping_id = extras.extras_id
    WHERE co.extras <> 'null'
),
ORDERS AS (
    SELECT DISTINCT
        co.order_id,
        co.pizza_id,
        toppings.topping_id
    FROM 
        pizza_runner.customer_orders AS co
    INNER JOIN pizza_runner.pizza_recipes AS pr ON co.pizza_id = pr.pizza_id
    CROSS JOIN LATERAL (
        SELECT unnest(string_to_array(pr.toppings, ', '))::int AS topping_id
    ) AS toppings
),
ORDERS_WITH_EXTRAS_AND_EXCLUSIONS AS (
    SELECT
        o.order_id,
        o.pizza_id,
        CASE 
            WHEN o.pizza_id = 1 THEN 'Meat Lovers'
            ELSE pn.pizza_name
        END AS pizza, 
        string_agg(DISTINCT ext.topping_name, ', ') AS extras,
        string_agg(DISTINCT exc.topping_name, ', ') AS exclusions
    FROM 
        ORDERS AS o
    LEFT JOIN EXTRAS AS ext ON ext.order_id = o.order_id AND ext.pizza_id = o.pizza_id
    LEFT JOIN EXCLUSIONS AS exc ON exc.order_id = o.order_id AND exc.pizza_id = o.pizza_id AND exc.topping_id = o.topping_id 
    INNER JOIN pizza_runner.pizza_names AS pn ON o.pizza_id = pn.pizza_id
    GROUP BY 
        o.order_id,
        o.pizza_id,
        CASE 
            WHEN o.pizza_id = 1 THEN 'Meat Lovers'
            ELSE pn.pizza_name
        END
)

SELECT 
    order_id,
    pizza_id,
    CONCAT(pizza, 
        CASE WHEN exclusions IS NULL OR exclusions = '' THEN '' ELSE ' - Exclude ' || exclusions END,
        CASE WHEN extras IS NULL OR extras = '' THEN '' ELSE ' - Extra ' || extras END) AS order_item
FROM 
    ORDERS_WITH_EXTRAS_AND_EXCLUSIONS
ORDER BY 
    order_id;


-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: ""Meat Lovers: 2xBacon, Beef, ... , Salami"""

WITH EXCLUSIONS AS (
    SELECT 
        co.order_id,
        co.pizza_id,
        CAST(NULLIF(S.value, 'null') AS INT) AS topping_id
    FROM 
        pizza_runner.customer_orders AS co
    CROSS JOIN LATERAL (
        SELECT unnest(string_to_array(co.exclusions, ', ')) AS value
    ) AS S
    WHERE NULLIF(S.value, 'null') IS NOT NULL
),
EXTRAS AS (
    SELECT 
        co.order_id,
        co.pizza_id,
        CAST(NULLIF(S.value, 'null') AS INT) AS topping_id,
        t.topping_name
    FROM 
        pizza_runner.customer_orders AS co
    CROSS JOIN LATERAL (
        SELECT unnest(string_to_array(co.extras, ', ')) AS value
    ) AS S
    INNER JOIN pizza_runner.pizza_toppings AS t ON t.topping_id = CAST(NULLIF(S.value, 'null') AS INT)
    WHERE NULLIF(S.value, 'null') IS NOT NULL
),
ORDERS AS (
    SELECT DISTINCT
        co.order_id,
        co.pizza_id,
        CAST(NULLIF(S.value, 'null') AS INT) AS topping_id,
        t.topping_name
    FROM 
        pizza_runner.customer_orders AS co
    INNER JOIN pizza_runner.pizza_recipes AS pr ON co.pizza_id = pr.pizza_id
    CROSS JOIN LATERAL (
        SELECT unnest(string_to_array(pr.toppings, ', ')) AS value
    ) AS S
    INNER JOIN pizza_runner.pizza_toppings AS t ON t.topping_id = CAST(NULLIF(S.value, 'null') AS INT)
),
ORDERS_WITH_EXTRAS_AND_EXCLUSIONS AS (
    SELECT 
        o.order_id,
        o.pizza_id,
        o.topping_id,
        o.topping_name
    FROM 
        ORDERS AS o
    LEFT JOIN EXCLUSIONS AS exc ON exc.order_id = o.order_id AND exc.pizza_id = o.pizza_id AND exc.topping_id = o.topping_id
    WHERE exc.topping_id IS NULL

    UNION ALL 

    SELECT 
        extras.order_id,
        extras.pizza_id,
        extras.topping_id,
        extras.topping_name
    FROM 
        EXTRAS AS extras
),
TOPPING_COUNT AS (
    SELECT 
        o.order_id,
        o.pizza_id,
        o.topping_name,
        COUNT(*) AS n
    FROM 
        ORDERS_WITH_EXTRAS_AND_EXCLUSIONS AS o
    GROUP BY 
        o.order_id,
        o.pizza_id,
        o.topping_name
)
SELECT 
    order_id,
    pizza_id,
    string_agg(
        CASE
            WHEN n > 1 THEN n || 'x' || topping_name
            ELSE topping_name
        END, ', ') AS ingredient
FROM 
    TOPPING_COUNT
GROUP BY 
    order_id,
    pizza_id
ORDER BY 
    order_id;


-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH EXCLUSIONS AS (
    SELECT 
        co.order_id,
        co.pizza_id,
        CAST(NULLIF(S.value, 'null') AS INT) AS topping_id
    FROM 
        pizza_runner.customer_orders AS co
    CROSS JOIN LATERAL (
        SELECT unnest(string_to_array(co.exclusions, ', ')) AS value
    ) AS S
    WHERE NULLIF(S.value, 'null') IS NOT NULL
),
EXTRAS AS (
    SELECT 
        co.order_id,
        co.pizza_id,
        CAST(NULLIF(S.value, 'null') AS INT) AS topping_id,
        t.topping_name
    FROM 
        pizza_runner.customer_orders AS co
    CROSS JOIN LATERAL (
        SELECT unnest(string_to_array(co.extras, ', ')) AS value
    ) AS S
    INNER JOIN pizza_runner.pizza_toppings AS t ON t.topping_id = CAST(NULLIF(S.value, 'null') AS INT)
    WHERE NULLIF(S.value, 'null') IS NOT NULL
),
ORDERS AS (
    SELECT DISTINCT
        co.order_id,
        co.pizza_id,
        CAST(NULLIF(S.value, 'null') AS INT) AS topping_id,
        t.topping_name
    FROM 
        pizza_runner.customer_orders AS co
    INNER JOIN pizza_runner.pizza_recipes AS pr ON co.pizza_id = pr.pizza_id
    CROSS JOIN LATERAL (
        SELECT unnest(string_to_array(pr.toppings, ', ')) AS value
    ) AS S
    INNER JOIN pizza_runner.pizza_toppings AS t ON t.topping_id = CAST(NULLIF(S.value, 'null') AS INT)
),
ORDERS_WITH_EXTRAS_AND_EXCLUSIONS AS (
    SELECT 
        o.order_id,
        o.pizza_id,
        o.topping_id,
        o.topping_name
    FROM 
        ORDERS AS o
    LEFT JOIN EXCLUSIONS AS exc ON exc.order_id = o.order_id AND exc.pizza_id = o.pizza_id AND exc.topping_id = o.topping_id
    WHERE exc.topping_id IS NULL

    UNION ALL 

    SELECT 
        extras.order_id,
        extras.pizza_id,
        extras.topping_id,
        extras.topping_name
    FROM 
        EXTRAS AS extras
)
SELECT 
    topping_id,
    topping_name,
    COUNT(pizza_id) AS times_used
FROM 
    ORDERS_WITH_EXTRAS_AND_EXCLUSIONS AS O
INNER JOIN pizza_runner.runner_orders AS ro ON O.order_id = ro.order_id
WHERE ro.cancellation = 'null'
GROUP BY 
    topping_id,
    topping_name
ORDER BY 
    times_used DESC,
    topping_id ASC;
