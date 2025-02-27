
WITH RECURSIVE sales_data AS (
    SELECT 
        s_store_sk, 
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
    UNION ALL
    SELECT 
        s_store_sk, 
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        s_store_sk
), income_data AS (
    SELECT 
        hd_in.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(c.c_birth_year) AS avg_birth_year
    FROM 
        household_demographics hd_in
    JOIN 
        customer c ON hd_in.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd_in.hd_income_band_sk
), return_data AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_amt) AS total_return
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
), combined_sales AS (
    SELECT 
        sd.s_store_sk,
        sd.total_sales,
        COALESCE(rd.total_return, 0) AS total_return
    FROM 
        sales_data sd
    LEFT OUTER JOIN return_data rd ON sd.s_store_sk = rd.sr_store_sk
)
SELECT 
    cs.hd_income_band_sk,
    cs.total_sales,
    cs.total_return,
    cs.total_sales - cs.total_return AS net_sales,
    id.customer_count,
    id.avg_birth_year
FROM 
    combined_sales cs
JOIN 
    income_data id ON cs.s_store_sk IN (
        SELECT s_store_sk 
        FROM store 
        WHERE s_closed_date_sk IS NULL
    )
WHERE 
    cs.total_sales > 50000
ORDER BY 
    net_sales DESC
LIMIT 10;
