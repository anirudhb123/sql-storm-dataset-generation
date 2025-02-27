
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
           1 AS level
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    
    UNION ALL

    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           COALESCE(SUM(ws.ws_net_profit), 0) + sh.total_profit AS total_profit,
           level + 1
    FROM customer c
    JOIN SalesHierarchy sh ON c.c_current_addr_sk = sh.c_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, sh.total_profit
)
SELECT 
    sh.c_customer_sk,
    CONCAT(sh.c_first_name, ' ', sh.c_last_name) AS full_name,
    sh.cd_gender,
    sh.cd_marital_status,
    sh.total_profit,
    CASE 
        WHEN sh.total_profit > 1000 THEN 'High'
        WHEN sh.total_profit BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END AS profitability,
    RANK() OVER (PARTITION BY sh.cd_gender ORDER BY sh.total_profit DESC) AS gender_rank
FROM SalesHierarchy sh
WHERE sh.total_profit IS NOT NULL
ORDER BY sh.total_profit DESC
LIMIT 100;

WITH IncomeRanges AS (
    SELECT ib_income_band_sk, 
           ib_lower_bound, 
           ib_upper_bound 
    FROM income_band
), CustomerIncome AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_marital_status, 
           COALESCE(ROUND(AVG(CASE 
               WHEN i.i_current_price IS NOT NULL THEN i.i_current_price 
               ELSE 0 
           END), 2), 0) AS avg_item_price
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN item i ON c.c_customer_sk = i.i_item_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status
)
SELECT ci.c_customer_sk, 
       ci.c_first_name, 
       ci.c_last_name, 
       ci.cd_marital_status,
       ir.ib_income_band_sk,
       ir.ib_lower_bound,
       ir.ib_upper_bound
FROM CustomerIncome ci
LEFT JOIN IncomeRanges ir ON ci.avg_item_price BETWEEN ir.ib_lower_bound AND ir.ib_upper_bound
WHERE ci.avg_item_price IS NOT NULL
ORDER BY ci.avg_item_price DESC;
