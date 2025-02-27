
WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_id
),
demographic_summary AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_catalog_sales) AS avg_catalog_sales,
        AVG(total_store_sales) AS avg_store_sales,
        COUNT(*) AS customer_count
    FROM customer_sales cs
    JOIN customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.avg_web_sales,
    ds.avg_catalog_sales,
    ds.avg_store_sales,
    ds.customer_count
FROM demographic_summary ds
ORDER BY ds.customer_count DESC
LIMIT 10;
