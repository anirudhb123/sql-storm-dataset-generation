
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        d.cd_gender,
        d.cd_marital_status,
        CASE 
            WHEN total_web_sales IS NOT NULL THEN 'Web Sales'
            WHEN total_catalog_sales IS NOT NULL THEN 'Catalog Sales'
            WHEN total_store_sales IS NOT NULL THEN 'Store Sales'
            ELSE 'No Sales'
        END AS sales_channel
    FROM CustomerSales cs
    LEFT JOIN Demographics d ON cs.c_customer_id = d.cd_demo_sk
)
SELECT 
    COUNT(*) AS total_customers,
    sales_channel,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_store_sales) AS avg_store_sales
FROM SalesSummary
GROUP BY sales_channel
ORDER BY total_customers DESC;
