
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
),
sales_with_details AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        sa.total_sales,
        sa.total_orders,
        sa.avg_order_value,
        ai.ca_city,
        ai.ca_state,
        ai.ca_country
    FROM 
        customer_details cd
    JOIN 
        sales_summary sa ON cd.c_customer_sk = sa.ws_bill_customer_sk
    JOIN 
        address_info ai ON cd.c_current_addr_sk = ai.ca_address_sk
)
SELECT 
    city,
    state,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS total_sales,
    AVG(avg_order_value) AS avg_order_value
FROM 
    sales_with_details
GROUP BY 
    city, state
ORDER BY 
    total_sales DESC
LIMIT 10;
