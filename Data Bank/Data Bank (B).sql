-- DATA BANK (B)


-- 1) What is the unique count and total amount for each transaction type?

SELECT 
txn_type,
COUNT(*) as unique_count,
SUM(txn_amount) as total_amount
FROM data_bank.customer_nodes as t1
GROUP BY txn_type;

-- 2) What is the average total historical deposit counts and amounts for all customers?

WITH T1 AS (
SELECT 
customer_id,
AVG(txn_amount) as avg_deposit,
COUNT(*) as transaction_count
FROM data_bank.customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id
)
SELECT 
ROUND(AVG(avg_deposit),2) as avg_deposit_amount,
ROUND(AVG(transaction_count),0) as avg_transactions
FROM T1;

-- 3) For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

WITH T1 AS (
SELECT 
DATE_TRUNC('month',txn_date) as month,
customer_id,
SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) as deposits,
SUM(CASE WHEN txn_type <> 'deposit' THEN 1 ELSE 0 END) as purchase_or_withdrawal
FROM data_bank.customer_transactions
GROUP BY DATE_TRUNC('month',txn_date),
customer_id
HAVING SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) > 1
AND SUM(CASE WHEN txn_type <> 'deposit' THEN 1 ELSE 0 END) = 1
)
SELECT 
month,
COUNT(customer_id) as customers
FROM T1
GROUP BY month;

-- 4) What is the closing balance for each customer at the end of the month?

WITH monthly AS(
SELECT 
DATE_TRUNC('month',txn_date) as txn_month,
txn_date,
customer_id,
SUM((CASE WHEN txn_type ='deposit' THEN txn_amount ELSE 0 END) - (CASE WHEN txn_type <>'deposit' THEN txn_amount ELSE 0 END)) as balance
FROM data_bank.customer_transactions
GROUP BY DATE_TRUNC('month',txn_date),txn_date,customer_id)

, total_balance AS (
SELECT 
*,
SUM(balance) OVER (PARTITION BY customer_id ORDER BY txn_date) as running_sum
,ROW_NUMBER() OVER (PARTITION BY customer_id, txn_month ORDER BY txn_date DESC) as rn
FROM monthly
ORDER BY txn_date
)

SELECT 
customer_id,
DATE_TRUNC('month', txn_month) + INTERVAL '1 month' - INTERVAL '1 day' AS end_of_month,
running_sum as closing_balance
FROM total_balance 
WHERE rn = 1;

-- 5) What is the percentage of customers who increase their closing balance by more than 5%?

WITH monthly AS(
SELECT 
DATE_TRUNC('month',txn_date) as txn_month,
txn_date,
customer_id,
SUM((CASE WHEN txn_type ='deposit' THEN txn_amount ELSE 0 END) - (CASE WHEN txn_type <>'deposit' THEN txn_amount ELSE 0 END)) as balance
FROM data_bank.customer_transactions
GROUP BY DATE_TRUNC('month',txn_date),txn_date,customer_id)

, total_balance AS (
SELECT 
*,
SUM(balance) OVER (PARTITION BY customer_id ORDER BY txn_date) as running_sum
,ROW_NUMBER() OVER (PARTITION BY customer_id, txn_month ORDER BY txn_date DESC) as rn
FROM monthly
ORDER BY txn_date
),

close_balance AS (
SELECT 
customer_id,
DATE_TRUNC('month', txn_month) + INTERVAL '1 month' - INTERVAL '1 day' AS eom,
DATE_TRUNC('month', txn_month) - INTERVAL '1 day'  as prev_eom,
running_sum as closing_balance
FROM total_balance 
WHERE rn = 1),

pct_increase AS (
SELECT 
CB1.customer_id,
CB1.eom,
CB1.closing_balance,
CB2.closing_balance as next_month_closing_balance,
(CB2.closing_balance / CB1.closing_balance) -1 as percentage_increase,
CASE WHEN (CB2.closing_balance > CB1.closing_balance AND 
(CB2.closing_balance / CB1.closing_balance) -1 > 0.05) THEN 1 ELSE 0 END as pct_inc_flag
FROM close_balance as CB1
INNER JOIN close_balance as CB2 on CB1.eom = CB2.prev_eom 
AND CB1.customer_id = CB2.customer_id
WHERE CB1.closing_balance <> 0
)

SELECT 
    ROUND(CAST(SUM(pct_inc_flag) AS numeric) / NULLIF(COUNT(pct_inc_flag), 0) * 100, 0) AS inc_abv_5pct
FROM pct_increase;"
