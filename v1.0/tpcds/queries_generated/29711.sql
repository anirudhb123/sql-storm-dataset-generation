
WITH address_data AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
matched_customers AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM customer c
    JOIN address_data a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_sales_price,
        ws.ws_quantity,
        mc.c_first_name,
        mc.c_last_name,
        mc.full_address
    FROM web_sales ws
    JOIN matched_customers mc ON ws.ws_bill_customer_sk = mc.c_customer_sk
),
aggregated_sales AS (
    SELECT 
        c_first_name,
        c_last_name,
        full_address,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM sales_data
    GROUP BY 
        c_first_name, 
        c_last_name, 
        full_address
)
SELECT 
    c_first_name,
    c_last_name,
    full_address,
    total_profit,
    total_sales,
    total_quantity,
    CASE 
        WHEN total_profit > 10000 THEN 'High Profit'
        WHEN total_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM aggregated_sales
ORDER BY total_profit DESC;
