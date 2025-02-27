
WITH RECURSIVE daily_sales AS (
    SELECT 
        d.d_date AS sales_date,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date

    UNION ALL

    SELECT 
        d.d_date AS sales_date,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY 
        d.d_date
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        ROUND(SUM(ws.ws_ext_sales_price), 2) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
sales_rank AS (
    SELECT 
        c.c_customer_sk,
        c.cd_gender,
        c.cd_marital_status,
        c.income_band,
        c.total_web_sales,
        RANK() OVER (PARTITION BY c.income_band ORDER BY c.total_web_sales DESC) AS sales_rank
    FROM 
        customer_info c
)
SELECT 
    sr.c_customer_sk,
    sr.cd_gender,
    sr.cd_marital_status,
    sr.income_band,
    sr.total_web_sales,
    sr.sales_rank,
    CASE
        WHEN sr.total_web_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status,
    (SELECT 
        COUNT(DISTINCT ws.ws_order_number) 
     FROM 
        web_sales ws 
     WHERE 
        ws.ws_bill_customer_sk = sr.c_customer_sk) AS order_count,
    (SELECT 
        COUNT(DISTINCT sr_sr.returned_date_sk)
     FROM 
        store_returns sr_sr 
     WHERE 
        sr_sr.sr_customer_sk = sr.c_customer_sk) AS store_return_count
FROM 
    sales_rank sr
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.income_band, sr.sales_rank;
