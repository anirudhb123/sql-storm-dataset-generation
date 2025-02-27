
WITH RECURSIVE CustomerReturns AS (
    SELECT sr_customer_sk, 
           SUM(sr_return_quantity) AS total_quantity_returned
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name || ' ' || c.c_last_name AS full_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(sr.return_quantity) DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT tc.full_name, 
       tc.cd_gender, 
       COALESCE(CR.total_quantity_returned, 0) AS total_returns,
       CASE
           WHEN tc.cd_gender = 'F' AND tc.total_returns > 10 THEN 'VIP'
           WHEN tc.cd_gender = 'M' AND tc.total_returns <= 5 THEN 'Newbie'
           ELSE 'Regular'
       END AS customer_category
FROM TopCustomers tc
LEFT JOIN CustomerReturns CR ON tc.c_customer_sk = CR.sr_customer_sk
WHERE tc.rn <= 5 
AND (tc.cd_purchase_estimate > 1000 OR CR.total_quantity_returned IS NULL)
ORDER BY total_returns DESC, tc.full_name;
