
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        ss_item_sk,
        total_quantity,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        sales_summary 
    WHERE 
        rank <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, hd.hd_income_band_sk
),
sales_by_gender AS (
    SELECT 
        ci.gender,
        SUM(ts.total_quantity) AS gender_quantity,
        SUM(ts.total_sales) AS gender_sales
    FROM 
        top_sales ts
    JOIN 
        customer_info ci ON ci.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ts.ss_item_sk)
    GROUP BY 
        ci.gender
)
SELECT 
    g.gender,
    g.gender_quantity,
    g.gender_sales,
    g.gender_sales / NULLIF(SUM(gender_sales) OVER (), 0) * 100 AS percentage_of_total_sales
FROM 
    sales_by_gender g
ORDER BY 
    g.gender_sales DESC;

