DANNY'S DINER

https://8weeksqlchallenge.com/case-study-1/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT sales.customer_id,SUM(menu.price)
FROM dannys_diner.sales LEFT JOIN dannys_diner.menu 
ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
GROUP BY sales.customer_id


-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date)
FROM dannys_diner.sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?
SELECT customer_id,order_date,product_name FROM
	(
	SELECT 
	customer_id,
	order_date,
	product_name, 
	RANK() OVER(PARTITION BY customer_id ORDER BY order_date) as rnk
	FROM
	dannys_diner.sales INNER JOIN dannys_diner.menu ON
	sales.product_id = menu.product_id
	) AS tb1
WHERE tb1.rnk=1


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
product_name,
COUNT(order_date) AS orders
FROM
dannys_diner.sales INNER JOIN dannys_diner.menu 
ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY orders DESC
LIMIT 1


-- 5. Which item was the most popular for each customer?
WITH CTE AS(
SELECT
customer_id,
product_name,
COUNT(order_date) AS orders,
RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(order_date) DESC ) AS rnk
FROM
dannys_diner.sales INNER JOIN dannys_diner.menu 
ON sales.product_id = menu.product_id
GROUP BY customer_id,product_name
ORDER BY orders DESC
  )
 
SELECT customer_id,product_name,orders
FROM CTE 
WHERE rnk=1

-- 6. Which item was purchased first by the customer after they became a member?
WITH CTE AS(
SELECT S.customer_id,order_date,join_date,menu.product_name,
RANK() OVER (PARTITION BY S.customer_id ORDER BY order_date ASC) as rnk
FROM 
dannys_diner.sales as S
INNER JOIN dannys_diner.members as mem ON S.customer_id=mem.customer_id
INNER JOIN dannys_diner.menu as menu ON S.product_id=menu.product_id
WHERE order_date>=join_date
  )
SELECT customer_id,product_name FROM 
CTE
where rnk=1


-- 7. Which item was purchased just before the customer became a member?
WITH T2 AS(
SELECT S.customer_id,order_date,join_date,menu.product_name,
RANK() OVER (PARTITION BY S.customer_id ORDER BY order_date DESC) as rnk
FROM 
dannys_diner.sales as S
INNER JOIN dannys_diner.members as mem ON S.customer_id=mem.customer_id
INNER JOIN dannys_diner.menu as menu ON S.product_id=menu.product_id
WHERE order_date<join_date
  )
SELECT customer_id,product_name FROM 
T2
WHERE 
rnk=1


-- 8. What is the total items and amount spent for each member before they became a member?
SELECT S.customer_id,SUM(price) as amt_spent,COUNT(S.product_id) as total_items
FROM 
dannys_diner.sales as S
INNER JOIN dannys_diner.members as mem ON S.customer_id=mem.customer_id
INNER JOIN dannys_diner.menu as menu ON S.product_id=menu.product_id
WHERE order_date<join_date
GROUP BY S.customer_id
ORDER BY S.customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT S.customer_id,
SUM(CASE menu.product_name
WHEN 'sushi' THEN price*20
ELSE price*10
END)
FROM 
dannys_diner.sales as S
INNER JOIN dannys_diner.menu as menu ON S.product_id=menu.product_id
GROUP BY S.customer_id
ORDER BY S.customer_id



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT S.customer_id,
SUM( 
  CASE WHEN S.order_date BETWEEN mem.join_date AND mem.join_date+6 THEN price*20
  WHEN product_name = 'sushi' THEN price * 10 * 2 
  ELSE price*10 END) as points
FROM dannys_diner.sales as S
INNER JOIN dannys_diner.members as mem
ON S.customer_id=mem.customer_id
INNER JOIN dannys_diner.menu as menu
ON S.product_id=menu.product_id
WHERE DATE_PART('month',S.order_date)=1
GROUP BY S.customer_id
ORDER BY S.customer_id


-- Bonus Question
WITH Temp1 AS(
SELECT S.customer_id, order_date, product_name,price,
CASE 
WHEN join_date IS NULL THEN 'N'
WHEN order_date < join_date THEN 'N' 
ELSE 'Y' 
END as member 
FROM dannys_diner.sales as S
LEFT JOIN dannys_diner.menu as menu ON S.product_id=menu.product_id
LEFT JOIN dannys_diner.members as mem ON S.customer_id=mem.customer_id
ORDER BY S.customer_id,order_date ASC)

SELECT *,
CASE
WHEN member='N' THEN NULL
ELSE RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date)
END as rnk
FROM TEMP1
