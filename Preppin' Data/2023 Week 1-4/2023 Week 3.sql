-- https://preppindata.blogspot.com/2023/01/2023-week-3-targets-for-dsb.html

 /* REQUIREMENTS

-- For the transactions file:
- Filter the transactions to just look at DSB 
  - These will be transactions that contain DSB in the Transaction Code field
- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values
- Change the date to be the quarter 
- Sum the transaction values for each quarter and for each Type of Transaction (Online or In-Person)

For the targets file:
- Pivot the quarterly targets so we have a row for each Type of Transaction and each Quarter (help)
- Rename the fields
- Remove the 'Q' from the quarter field and make the data type numeric (help)

Join the two datasets together 
- You may need more than one join clause!

Remove unnecessary fields
Calculate the Variance to Target for each row
Output the data */


WITH target AS (
    SELECT 
        online_or_in_person,
        quarter,
        target
    FROM 
        pd2023_wk03_targets,
    		LATERAL (
            VALUES 
                ('1', q1),
                ('2', q2),
                ('3', q3),
                ('4', q4)
        ) AS unpivoted(quarter, target)
),

transactions AS (
    SELECT
        CASE 
            WHEN online_or_in_person = 1 THEN 'Online'
            WHEN online_or_in_person = 2 THEN 'In-Person'
            ELSE NULL 
        END AS online_in_person,
        TO_CHAR(TO_DATE(transaction_date, 'DD/MM/YYYY HH24:MI:SS'), 'Q') AS quarter,
        SUM(value) AS value
    FROM pd2023_wk01
    WHERE SPLIT_PART(transaction_code, '-', 1) = 'DSB'
    GROUP BY online_in_person, quarter
)

SELECT online_or_in_person,transactions.quarter,value,
target as Quarterly_Targets, value-target AS variance_to_targets
FROM transactions 
INNER JOIN target
ON transactions.online_in_person = target.online_or_in_person
AND transactions.quarter = target.quarter
ORDER BY online_or_in_person,quarter ASC;
