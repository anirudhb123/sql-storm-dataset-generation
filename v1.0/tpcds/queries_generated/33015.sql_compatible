
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
latest_sales AS (
    SELECT 
        ss_item_sk,
        total_quantity,
        total_sales
    FROM 
        sales_summary
    WHERE 
        rn = 1
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN 'Known'
            ELSE 'Unknown' 
        END AS income_band_status
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.income_band_status,
    COALESCE(ls.total_quantity, 0) AS last_period_quantity,
    COALESCE(ls.total_sales, 0.00) AS last_period_sales,
    (SELECT COUNT(*) FROM store WHERE s_state = 'CA') AS store_count,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk) FROM web_sales WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)) AS unique_customers
FROM 
    customer_info ci
    LEFT JOIN latest_sales ls ON ci.c_customer_sk = ls.ws_item_sk
WHERE 
    (ci.cd_gender = 'M' OR ci.cd_marital_status = 'M') 
    AND ci.income_band_status = 'Known'
ORDER BY 
    ci.c_last_name,
    ci.c_first_name;
