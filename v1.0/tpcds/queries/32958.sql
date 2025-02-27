
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, 
           SUM(ws.ws_net_profit) AS total_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
             cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
    UNION ALL
    SELECT sh.c_customer_sk, sh.c_customer_id, sh.c_first_name, sh.c_last_name, 
           sh.cd_gender, sh.cd_marital_status, sh.cd_credit_rating,
           SUM(ws.ws_net_profit) AS total_sales
    FROM sales_hierarchy sh
    JOIN web_sales ws ON sh.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY sh.c_customer_sk, sh.c_customer_id, sh.c_first_name, sh.c_last_name, 
             sh.cd_gender, sh.cd_marital_status, sh.cd_credit_rating
),
customer_sales AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name,
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
           COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_profit,
           COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit,
           DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT *, 
           CASE 
               WHEN total_net_profit > 1000 THEN 'High' 
               WHEN total_net_profit BETWEEN 500 AND 1000 THEN 'Medium' 
               ELSE 'Low' 
           END AS customer_value
    FROM customer_sales
)
SELECT hvc.c_customer_sk, hvc.c_customer_id, hvc.c_first_name, hvc.c_last_name,
       hvc.total_net_profit, hvc.total_catalog_profit, hvc.total_store_profit, 
       hvc.customer_value, hvc.sales_rank
FROM high_value_customers hvc
WHERE hvc.sales_rank <= 10
ORDER BY hvc.total_net_profit DESC;
