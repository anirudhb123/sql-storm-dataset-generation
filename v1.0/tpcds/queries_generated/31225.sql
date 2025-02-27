
WITH RECURSIVE sales_periods AS (
    SELECT 
        d_date_sk,
        d_year,
        d_month_seq,
        d_quarter_seq,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY d_month_seq) AS month_rank
    FROM 
        date_dim
    WHERE 
        d_year >= 2020
),
customer_totals AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws_ext_sales_price, 0) + COALESCE(cs_ext_sales_price, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ss_ext_sales_price) AS store_sales_total,
        SUM(ws_ext_sales_price) AS web_sales_total,
        SUM(cs_ext_sales_price) AS catalog_sales_total
    FROM 
        date_dim d
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE 
        d.d_year = 2021
    GROUP BY 
        d.d_date
),
composite_sales AS (
    SELECT
        dp.d_year,
        SUM(ds.store_sales_total) AS total_store_sales,
        SUM(ds.web_sales_total) AS total_web_sales,
        SUM(ds.catalog_sales_total) AS total_catalog_sales
    FROM 
        sales_periods dp
    JOIN 
        daily_sales ds ON dp.d_date_sk = ds.d_date_sk
    GROUP BY 
        dp.d_year
)
SELECT 
    ct.c_first_name,
    ct.c_last_name,
    COALESCE(sp.total_store_sales, 0) AS store_sales,
    COALESCE(sp.total_web_sales, 0) AS web_sales,
    COALESCE(sp.total_catalog_sales, 0) AS catalog_sales,
    (COALESCE(sp.total_store_sales, 0) 
    + COALESCE(sp.total_web_sales, 0) 
    + COALESCE(sp.total_catalog_sales, 0)) AS total_sales,
    CASE 
        WHEN ct.total_sales IS NOT NULL AND ct.total_sales > 10000 THEN 'VIP'
        ELSE 'Regular'
    END AS customer_type
FROM 
    customer_totals ct
LEFT JOIN 
    composite_sales sp ON ct.c_customer_sk = sp.c_customer_sk
WHERE 
    sp.total_store_sales > 0 OR sp.total_web_sales > 0 OR sp.total_catalog_sales > 0
ORDER BY 
    total_sales DESC;
