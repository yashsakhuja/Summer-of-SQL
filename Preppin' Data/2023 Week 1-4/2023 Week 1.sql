--https://preppindata.blogspot.com/2023/01/2023-week-1-data-source-bank.html

-- REQUIREMENTS

-- Split the Transaction Code to extract the letters at the start of the transaction code. These identify the bank who processes the transaction
-- Rename the new field with the Bank code 'Bank'. 
-- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values. 
-- Change the date to be the day of the week"

SELECT *,SPLIT_PART(transaction_code, '-', 1) AS Bank,
CASE 
	WHEN online_or_in_person = 1 THEN 'Online'
    WHEN online_or_in_person = 2 THEN 'In-Person'
    ELSE NULL 
    END AS online_in_person,
TO_CHAR(TO_DATE(transaction_date, 'DD/MM/YYYY HH24:MI:SS'), 'Day') AS transaction_day
FROM pd2023_wk01
LIMIT 100;

-- 1. Total Values of Transactions by each bank
SELECT SPLIT_PART(transaction_code, '-', 1) AS Bank, SUM(value) AS total_value
FROM pd2023_wk01
GROUP BY Bank

-- 2. Total Values by Bank, Day of the Week and Type of Transaction (Online or In-Person)
SELECT SPLIT_PART(transaction_code, '-', 1) AS Bank,
CASE 
	WHEN online_or_in_person = 1 THEN 'Online'
    WHEN online_or_in_person = 2 THEN 'In-Person'
    ELSE NULL 
    END AS online_in_person,
    TO_CHAR(TO_DATE(transaction_date, 'DD/MM/YYYY HH24:MI:SS'), 'Day') AS transaction_day,
SUM(value) as total_value
FROM pd2023_wk01
GROUP BY Bank,transaction_day,online_in_person

-- 3. Total Values by Bank and Customer Code
SELECT SPLIT_PART(transaction_code, '-', 1) AS Bank,
customer_code, SUM(value) as total_value
FROM pd2023_wk01
GROUP BY Bank,customer_code
