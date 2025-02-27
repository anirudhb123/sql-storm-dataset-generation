
WITH customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.ca_state,
        ss.total_sales,
        ss.order_count
    FROM customer_details cd
    JOIN sales_summary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
    WHERE ss.total_sales > 1000
)
SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name,
    city,
    state,
    total_sales,
    order_count,
    CASE 
        WHEN total_sales > 5000 THEN 'Platinum'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Gold'
        ELSE 'Silver'
    END AS customer_tier
FROM high_value_customers
ORDER BY total_sales DESC, order_count DESC
LIMIT 50;
