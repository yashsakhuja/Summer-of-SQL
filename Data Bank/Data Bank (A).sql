-- DATA BANK (A)


-- 1. How many unique nodes are there on the Data Bank system?

SELECT 
COUNT(DISTINCT node_id) as unique_nodes 
FROM data_bank.customer_nodes;


-- 2. What is the number of nodes per region?

SELECT 
region_name,COUNT(DISTINCT node_id) as nodes
FROM data_bank.customer_nodes as t1
INNER JOIN data_bank.regions as t2
ON t1.region_id=t2.region_id
GROUP BY region_name;

-- 3. How many customers are allocated to each region?

SELECT 
region_name,COUNT(DISTINCT customer_id) as unique_customers
FROM data_bank.customer_nodes as t1
INNER JOIN data_bank.regions as t2
ON t1.region_id=t2.region_id
GROUP BY region_name;

-- 4. How many days on average are customers reallocated to a different node?

WITH T1 AS(
SELECT 
customer_id,
node_id,
SUM(end_date - start_date) AS total_days
FROM data_bank.customer_nodes
WHERE end_date <> '9999-12-31'
GROUP BY customer_id,node_id)

SELECT 
ROUND(AVG(total_days),0) as average_days
FROM T1;


-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH T1 AS( 
SELECT 
region_name, 
customer_id, 
node_id, 
SUM(end_date - start_date) AS total_days 
FROM data_bank.customer_nodes as t1 
INNER JOIN data_bank.regions as t2 
ON t1.region_id=t2.region_id 
WHERE end_date <> '9999-12-31' 
GROUP BY region_name,customer_id,node_id), 

Sorted_T1 AS ( 
SELECT 
region_name, 
total_days, 
ROW_NUMBER() OVER(PARTITION BY region_name ORDER BY total_days) as rn 
FROM T1), 

Max_T1 as ( 
SELECT 
region_name, 
MAX(rn) as max_rn 
FROM Sorted_T1 
GROUP BY region_name 
), 

U_F_T AS 
(SELECT S_T1.region_name, 
CASE 
WHEN rn = ROUND(M_S_T1.max_rn *0.5,0) THEN 'Median' 
WHEN rn = ROUND(M_S_T1.max_rn * 0.8,0) THEN '80th Percentile' 
WHEN rn = ROUND(M_S_T1.max_rn * 0.95,0) THEN '95th Percentile' 
END as metric, 
total_days as value 
FROM Sorted_T1 as S_T1 
INNER JOIN Max_T1 as M_S_T1 
ON S_T1.region_name = M_S_T1.region_name 
WHERE rn IN ( 
ROUND(M_S_T1.max_rn *0.5,0), 
ROUND(M_S_T1.max_rn * 0.8,0), 
ROUND(M_S_T1.max_rn * 0.95,0)) 
) 

SELECT 
region_name, 
MAX(CASE WHEN metric = 'Median' THEN value END) AS ""Median"", 
MAX(CASE WHEN metric = '80th Percentile' THEN value END) AS ""80th Percentile"", 
MAX(CASE WHEN metric = '95th Percentile' THEN value END) AS ""95th Percentile"" 
FROM U_F_T 
GROUP BY region_name; 
