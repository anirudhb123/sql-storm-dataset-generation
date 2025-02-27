
WITH RECURSIVE sales_data AS (
    SELECT 
        ss.s_sold_date_sk, 
        ss.ws_item_sk, 
        SUM(ss.ss_quantity) AS total_quantity, 
        SUM(ss.ss_sales_price) AS total_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.s_sold_date_sk, ss.ws_item_sk
),
top_sales AS (
    SELECT 
        sd.s_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (PARTITION BY sd.s_sold_date_sk ORDER BY sd.total_sales DESC) as sales_rank
    FROM 
        sales_data sd
),
filtered_sales AS (
    SELECT 
        ts.s_sold_date_sk,
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_sales
    FROM 
        top_sales ts
    WHERE 
        ts.sales_rank <= 5
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
checked_returns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    sds.s_sold_date_sk,
    c.c_first_name,
    c.c_last_name,
    sds.ws_item_sk,
    COALESCE(sds.total_quantity, 0) AS total_quantity,
    COALESCE(sds.total_sales, 0.00) AS total_sales,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amt, 0.00) AS total_return_amt,
    cd.cd_income_band_sk
FROM 
    filtered_sales sds
JOIN 
    customer_data c ON sds.ws_item_sk = c.c_customer_sk
LEFT JOIN 
    checked_returns cr ON sds.ws_item_sk = cr.sr_item_sk
WHERE 
    c.cd_gender = 'F' 
    AND c.cd_income_band_sk IS NOT NULL
ORDER BY 
    sds.s_sold_date_sk, total_sales DESC;
