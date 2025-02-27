
WITH RECURSIVE sales_analysis AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ws_net_profit) AS total_profit
    FROM
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'F'
        AND hd.hd_income_band_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        hd.hd_income_band_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.d_year,
    ci.cd_gender,
    ci.hd_income_band_sk,
    COALESCE(SUM(sa.ws_quantity), 0) AS total_quantity,
    COALESCE(SUM(sa.ws_sales_price), 0) AS total_sales_value,
    CASE 
        WHEN AVG(ci.total_profit) > 1000 THEN 'High value customer'
        ELSE 'Regular customer'
    END AS customer_value_category
FROM 
    customer_info ci
LEFT JOIN 
    sales_analysis sa ON ci.c_customer_sk = sa.ws_customer_sk
GROUP BY 
    ci.c_first_name,
    ci.c_last_name,
    ci.d_year,
    ci.cd_gender,
    ci.hd_income_band_sk
ORDER BY 
    ci.d_year ASC,
    ci.total_profit DESC
LIMIT 100;
