
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws_ext_sales_price, 0) + COALESCE(cs_ext_sales_price, 0) + COALESCE(ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_education_status,
        cd.cd_dep_count,
        cs.total_sales
    FROM customer_demographics cd
    JOIN customer_sales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    SUM(total_sales) AS total_sales_sum,
    MAX(total_sales) AS max_sales,
    MIN(total_sales) AS min_sales
FROM customer_demo
GROUP BY cd_gender, cd_marital_status
ORDER BY total_sales_sum DESC
LIMIT 10;
