
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        1 AS level
    FROM store_sales
    GROUP BY ss_store_sk
    UNION ALL
    SELECT 
        p.ss_store_sk,
        p.total_sales * 0.9 AS total_sales,
        h.level + 1
    FROM sales_hierarchy h
    JOIN store s ON h.ss_store_sk = s.s_store_sk
    JOIN store_sales p ON s.s_store_sk = p.ss_store_sk
    WHERE h.level < 5
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
    COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_profit,
    COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit,
    RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS web_rank,
    DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(cs.cs_net_profit) DESC) AS catalog_rank
FROM customer c
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN sales_hierarchy sh ON sh.ss_store_sk = ss.ss_store_sk
WHERE cd.cd_gender = 'F'
  AND cd.cd_purchase_estimate > 100
  AND (c.c_birth_year < 1980 OR (c.c_birth_year = 1980 AND c.c_birth_month <= 6))
GROUP BY c.c_customer_id, cd.cd_gender, c.c_first_name, c.c_last_name
HAVING total_web_profit > 500
   OR total_catalog_profit > 300
   OR total_store_profit > 800
ORDER BY total_web_profit DESC, total_catalog_profit DESC, total_store_profit DESC;
