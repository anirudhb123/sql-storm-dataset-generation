
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_marital_status, cd.cd_gender, 
           c.c_birth_year, c.c_birth_month, c.c_birth_day,
           c.c_current_addr_sk, 0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           ch.cd_marital_status, ch.cd_gender, 
           ch.c_birth_year, ch.c_birth_month, ch.c_birth_day,
           ca.ca_address_sk, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer_address ca ON ch.c_current_addr_sk = ca.ca_address_sk
    WHERE level < 5
), RankedCustomers AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY c_birth_year ORDER BY c_birth_month, c_birth_day) AS rn,
           COUNT(*) OVER (PARTITION BY c_birth_year) AS total_count
    FROM CustomerHierarchy
), CustomerReturns AS (
    SELECT sr_customer_sk, SUM(sr_return_amt_inc_tax) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
), CustomerSales AS (
    SELECT ws_bill_customer_sk AS customer_sk, 
           SUM(ws_net_profit) AS total_sales,
           COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT c.c_first_name, c.c_last_name, 
       c.cd_gender, c.cd_marital_status, 
       CONVERT(varchar, DATENAME(month, DATEFROMPARTS(c.c_birth_year, c.c_birth_month, c.c_birth_day))) + ' ' + CAST(c.c_birth_day AS varchar) + ', ' + CAST(c.c_birth_year AS varchar) AS birth_date,
       rc.total_count, 
       COALESCE(cr.total_returns, 0) AS total_returns,
       COALESCE(cs.total_sales, 0) AS total_sales,
       COALESCE(cs.order_count, 0) AS order_count,
       (COALESCE(cs.total_sales, 0) - COALESCE(cr.total_returns, 0)) AS net_profit
FROM RankedCustomers rc
LEFT JOIN CustomerReturns cr ON rc.c_customer_sk = cr.sr_customer_sk
LEFT JOIN CustomerSales cs ON rc.c_customer_sk = cs.customer_sk
WHERE lower(c.cd_gender) = 'f' AND rc.level < 3
ORDER BY c_birth_year DESC, c_birth_month ASC, c_birth_day ASC;
