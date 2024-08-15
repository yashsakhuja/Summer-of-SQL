-- https://preppindata.blogspot.com/2023/01/2023-week-4-new-customers.html

/* REQUIREMENTS

- We want to stack the tables on top of one another, since they have the same fields in each sheet.
- Drag each table into the canvas and use a union step to stack them on top of one another
- Use a wildcard union in the input step of one of the tables
- Some of the fields aren't matching up as we'd expect, due to differences in spelling. Merge these fields together
- Make a Joining Date field based on the Joining Day, Table Names and the year 2023
- Now we want to reshape our data so we have a field for each demographic, for each new customer
- Make sure all the data types are correct for each field
- Remove duplicates 
- If a customer appears multiple times take their earliest joining date

Output the data  */

WITH union_tables AS (
  SELECT *, 'pd2023_wk04_january' as tablename FROM pd2023_wk04_january
  UNION ALL
  SELECT *, 'pd2023_wk04_february' as tablename FROM pd2023_wk04_february
  UNION ALL
  SELECT *, 'pd2023_wk04_march' as tablename FROM pd2023_wk04_march
  UNION ALL
  SELECT *, 'pd2023_wk04_april' as tablename FROM pd2023_wk04_april
  UNION ALL
  SELECT *, 'pd2023_wk04_may' as tablename FROM pd2023_wk04_may
  UNION ALL
  SELECT *, 'pd2023_wk04_june' as tablename FROM pd2023_wk04_june
  UNION ALL
  SELECT *, 'pd2023_wk04_july' as tablename FROM pd2023_wk04_july
  UNION ALL
  SELECT *, 'pd2023_wk04_august' as tablename FROM pd2023_wk04_august
  UNION ALL
  SELECT *, 'pd2023_wk04_september' as tablename FROM pd2023_wk04_september
  UNION ALL
  SELECT *, 'pd2023_wk04_october' as tablename FROM pd2023_wk04_october
  UNION ALL
  SELECT *, 'pd2023_wk04_november' as tablename FROM pd2023_wk04_november
  UNION ALL
  SELECT *, 'pd2023_wk04_december' as tablename FROM pd2023_wk04_december
)
,date_clean AS(
SELECT 
  ""ID"",
  ""Joining Day"",
  to_date(
    2023|| '-' ||
     EXTRACT(MONTH FROM to_date(split_part(""tablename"", '_', 3), 'Month'))|| '-' ||
    ""Joining Day"",
    'YYYY-MM-DD'
  ) AS joining_date,
  ""Demographic"",
  ""Value""
FROM union_tables
)
,data_pivot AS(
SELECT 
  ""ID"",
  joining_date,
  MAX(CASE WHEN ""Demographic"" = 'Ethnicity' THEN ""Value"" END) AS ethnicity,
  MAX(CASE WHEN ""Demographic"" = 'Account Type' THEN ""Value"" END) AS account_type,
  MAX(CASE WHEN ""Demographic"" = 'Date of Birth' THEN ""Value""::date END) AS date_of_birth,
  ROW_NUMBER() OVER(PARTITION BY ""ID"" ORDER BY joining_date ASC) as rnk
FROM date_clean
GROUP BY ""ID"", joining_date
)

SELECT 
""ID"",
 joining_date,
 ethnicity,
 account_type,
 date_of_birth
FROM data_pivot
WHERE rnk=1
