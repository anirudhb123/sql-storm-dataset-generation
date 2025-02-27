
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate, 
           cd.cd_credit_rating, 
           0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate, 
           cd.cd_credit_rating, 
           sh.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_hierarchy sh ON c.c_current_hdemo_sk = sh.c_customer_sk
    WHERE cd.cd_marital_status = 'S'
),
sales_data AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
combined_data AS (
    SELECT sh.c_customer_id, 
           sh.cd_gender, 
           sh.cd_marital_status, 
           COALESCE(sd.total_net_profit, 0) AS total_net_profit
    FROM sales_hierarchy sh
    LEFT JOIN sales_data sd ON sh.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT cd.cd_gender, 
       cd.cd_marital_status, 
       COUNT(*) AS customer_count, 
       AVG(cd.total_net_profit) AS avg_net_profit
FROM combined_data cd
GROUP BY cd.cd_gender, cd.cd_marital_status
HAVING AVG(cd.total_net_profit) > 1000
ORDER BY cd.cd_gender, cd.cd_marital_status;
