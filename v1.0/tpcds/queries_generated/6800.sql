
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
demographic_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS customer_count,
        SUM(cs.total_sales) AS demographic_sales
    FROM customer_sales cs
    JOIN customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    demographic_analysis.customer_count,
    demographic_analysis.demographic_sales,
    RANK() OVER (ORDER BY demographic_analysis.demographic_sales DESC) AS sales_rank
FROM demographic_analysis
JOIN customer_demographics cd ON demographic_analysis.cd_gender = cd.cd_gender AND demographic_analysis.cd_marital_status = cd.cd_marital_status
WHERE demographic_analysis.customer_count > 50
ORDER BY sales_rank;
