
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesStatistics AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(s.total_web_sales, 0) AS total_web_sales,
        COALESCE(s.total_catalog_sales, 0) AS total_catalog_sales,
        COALESCE(s.total_store_sales, 0) AS total_store_sales,
        RANK() OVER (ORDER BY COALESCE(s.total_web_sales, 0) + COALESCE(s.total_catalog_sales, 0) + COALESCE(s.total_store_sales, 0) DESC) AS sales_rank
    FROM
        customer c
    LEFT JOIN
        CustomerSales s ON c.c_customer_id = s.c_customer_id
),
IncomeBandStats AS (
    SELECT
        ib.ib_income_band_sk,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS total_catalog_sales
    FROM
        household_demographics hd
    JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN
        catalog_sales cs ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    JOIN
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY
        ib.ib_income_band_sk
)
SELECT
    s.c_customer_id,
    s.c_first_name,
    s.c_last_name,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales,
    ibs.customer_count,
    ibs.total_catalog_sales AS band_total_catalog_sales,
    CASE 
        WHEN ibs.total_catalog_sales > 10000 THEN 'High Value'
        WHEN ibs.total_catalog_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    SalesStatistics s
LEFT JOIN
    IncomeBandStats ibs ON s.c_customer_id IN (SELECT c.c_customer_id FROM customer c JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk WHERE hd.hd_income_band_sk = ibs.ib_income_band_sk)
WHERE
    s.sales_rank <= 50
ORDER BY
    s.total_web_sales DESC, s.total_catalog_sales DESC;
