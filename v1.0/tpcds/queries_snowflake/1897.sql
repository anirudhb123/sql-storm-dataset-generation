
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS web_order_count,
        COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS catalog_order_count,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
sales_analysis AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(cs.total_web_sales, 0) > COALESCE(cs.total_catalog_sales, 0)
            AND COALESCE(cs.total_web_sales, 0) > COALESCE(cs.total_store_sales, 0) THEN 'Web'
            WHEN COALESCE(cs.total_catalog_sales, 0) > COALESCE(cs.total_web_sales, 0)
            AND COALESCE(cs.total_catalog_sales, 0) > COALESCE(cs.total_store_sales, 0) THEN 'Catalog'
            ELSE 'Store'
        END AS preferred_channel
    FROM customer_sales cs
),
income_data AS (
    SELECT 
        cd.cd_demo_sk,
        d.d_year,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cast(hd.hd_income_band_sk AS integer)) AS total_income_band
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    GROUP BY cd.cd_demo_sk, d.d_year
)
SELECT 
    sa.c_customer_id,
    sa.total_web_sales,
    sa.total_catalog_sales,
    sa.total_store_sales,
    sa.total_sales,
    sa.preferred_channel,
    id.d_year,
    id.customer_count,
    id.total_income_band
FROM sales_analysis sa
JOIN income_data id ON sa.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk = id.cd_demo_sk LIMIT 1)
ORDER BY id.d_year DESC, sa.total_sales DESC
