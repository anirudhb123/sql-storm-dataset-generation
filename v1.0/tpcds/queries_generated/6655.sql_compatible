
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        wd.ib_upper_bound,
        wd.ib_lower_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN 
        income_band wd ON hd.hd_income_band_sk = wd.ib_income_band_sk
),
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    dd.d_date,
    SUM(sd.total_sales) AS aggregate_sales,
    SUM(sd.total_profit) AS aggregate_profit,
    SUM(sd.order_count) AS total_orders,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers
FROM 
    date_dim dd
LEFT JOIN 
    sales_data sd ON dd.d_date_sk = sd.ws_sold_date_sk
LEFT JOIN 
    customer_info ci ON ci.c_customer_sk IN (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_sold_date_sk = sd.ws_sold_date_sk)
WHERE 
    dd.d_year = 2023
GROUP BY 
    dd.d_date
ORDER BY 
    dd.d_date;
