
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.web_order_count,
        cs.catalog_order_count,
        RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales) DESC) AS sales_rank
    FROM
        CustomerSales cs
),
IncomeAnalysis AS (
    SELECT 
        hd.hd_income_band_sk,
        SUM(cs.total_web_sales) AS total_web_sales_in_band,
        SUM(cs.total_catalog_sales) AS total_catalog_sales_in_band,
        COUNT(cs.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    LEFT JOIN 
        CustomerSales cs ON cs.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk = hd.hd_demo_sk)
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT
    ra.c_first_name,
    ra.c_last_name,
    ra.total_web_sales,
    ra.total_catalog_sales,
    ra.sales_rank,
    ia.total_web_sales_in_band,
    ia.total_catalog_sales_in_band,
    ia.customer_count
FROM
    RankedSales ra
JOIN 
    IncomeAnalysis ia ON ra.c_customer_sk = ia.hd_income_band_sk
WHERE 
    ra.sales_rank <= 10
ORDER BY 
    ra.sales_rank;
