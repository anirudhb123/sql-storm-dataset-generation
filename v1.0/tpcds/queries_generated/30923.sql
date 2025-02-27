
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           cd.cd_gender,
           cd.cd_marital_status,
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    UNION ALL
    SELECT sh.c_customer_sk, 
           sh.c_customer_id, 
           sh.cd_gender,
           sh.cd_marital_status,
           SUM(store_sales.ss_net_profit) AS total_net_profit
    FROM sales_hierarchy sh
    JOIN store_sales ON sh.c_customer_sk = store_sales.ss_customer_sk
    GROUP BY sh.c_customer_sk, sh.c_customer_id, sh.cd_gender, sh.cd_marital_status
), sales_summary AS (
    SELECT sh.c_customer_id,
           sh.cd_gender,
           sh.cd_marital_status,
           sh.total_net_profit,
           DENSE_RANK() OVER (PARTITION BY sh.cd_gender ORDER BY sh.total_net_profit DESC) AS gender_rank
    FROM sales_hierarchy sh
),
top_sales AS (
    SELECT gender_rank, 
           c_gender, 
           SUM(total_net_profit) AS total_gender_profit
    FROM sales_summary
    WHERE gender_rank <= 10
    GROUP BY gender_rank, cd_gender
)
SELECT t.c_gender, 
       t.total_gender_profit,
       COALESCE(ROUND(AVG(t.total_gender_profit), 2), 0.00) AS avg_gender_profit,
       CONCAT('Top', CAST(t.gender_rank AS CHAR), ' - ', t.c_gender, ': ', CAST(t.total_gender_profit AS CHAR)) AS rank_desc
FROM top_sales t
JOIN (SELECT MAX(total_gender_profit) AS max_profit FROM top_sales) max_p ON t.total_gender_profit = max_p.max_profit
GROUP BY t.c_gender, t.gender_rank, t.total_gender_profit
ORDER BY t.gender_rank ASC;
