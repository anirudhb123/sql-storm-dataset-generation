
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        a.ca_city,
        a.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
customer_sales AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ss.total_sales,
        ss.order_count,
        ci.hd_buy_potential,
        ci.hd_dep_count,
        ci.hd_vehicle_count,
        ci.ca_city,
        ci.ca_state
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    city,
    state,
    COUNT(*) AS num_customers,
    AVG(total_sales) AS avg_sales,
    SUM(order_count) AS total_orders
FROM 
    customer_sales
GROUP BY 
    city, state
HAVING 
    COUNT(*) >= 10
ORDER BY 
    avg_sales DESC;
