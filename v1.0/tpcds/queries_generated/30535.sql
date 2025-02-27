
WITH RECURSIVE sales_hierarchy AS (
    SELECT ss.customer_sk, 
           SUM(ss.net_profit) AS total_net_profit,
           'store' AS sales_type
    FROM store_sales ss
    GROUP BY ss.customer_sk
    UNION ALL
    SELECT ws.bill_customer_sk, 
           SUM(ws.net_profit) AS total_net_profit,
           'web' AS sales_type
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
),
demographics_summary AS (
    SELECT c.c_customer_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           COALESCE(SUM(sh.total_net_profit), 0) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_hierarchy sh ON c.c_customer_sk = sh.customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT c.c_customer_sk,
           SUM(ds.total_sales) AS customer_total_sales,
           DENSE_RANK() OVER (ORDER BY SUM(ds.total_sales) DESC) AS sales_rank
    FROM demographics_summary ds
    JOIN customer c ON ds.c_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT tc.c_customer_sk, 
       ds.cd_gender, 
       ds.cd_marital_status, 
       tc.customer_total_sales,
       CASE WHEN tc.sales_rank <= 10 THEN 'Top 10' ELSE 'Others' END AS customer_group
FROM top_customers tc
JOIN demographics_summary ds ON tc.c_customer_sk = ds.c_customer_sk
WHERE ds.total_sales > 0
ORDER BY tc.customer_total_sales DESC
LIMIT 100;

-- Performance Benchmarking with NULL handling logic for missing demographic info
SELECT c.c_customer_id,
       COALESCE(cd.cd_gender, 'Unknown') AS gender,
       COALESCE(cd.cd_marital_status, 'Not Specified') AS marital_status,
       COUNT(ss.ss_ticket_number) AS store_sales_count,
       COUNT(ws.ws_order_number) AS web_sales_count,
       AVG(COALESCE(ss.ss_net_paid, 0)) AS avg_store_sales,
       AVG(COALESCE(ws.ws_net_paid, 0)) AS avg_web_sales
FROM customer c
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
HAVING COUNT(ss.ss_ticket_number) > 0 OR COUNT(ws.ws_order_number) > 0
ORDER BY avg_store_sales DESC, avg_web_sales DESC
LIMIT 50;
