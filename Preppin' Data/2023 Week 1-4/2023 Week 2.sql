-- https://preppindata.blogspot.com/2023/01/2023-week-2-international-bank-account.html

-- REQUIREMENTS

-- In the Transactions table, there is a Sort Code field which contains dashes. We need to remove these so just have a 6 digit string
-- Use the SWIFT Bank Code lookup table to bring in additional information about the SWIFT code and Check Digits of the receiving bank account
-- Add a field for the Country Code

-- Hint: all these transactions take place in the UK so the Country Code should be GB
-- Create the IBAN as above
-- Hint: watch out for trying to combine sting fields with numeric fields - check data types
-- Remove unnecessary fields
-- Output the data

SELECT transaction_id,CONCAT('GB',check_digits,swift_code,REPLACE(sort_code,'-',''),account_number) AS IBAN
FROM pd2023_wk02_transactions
INNER JOIN pd2023_wk02_swift_codes
ON pd2023_wk02_transactions.bank=pd2023_wk02_swift_codes.bank
LIMIT 100;
