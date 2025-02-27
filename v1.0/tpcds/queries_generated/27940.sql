
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        LENGTH(c.c_email_address) AS email_length
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
sales_report AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.email_length,
        ISNULL(is.total_quantity, 0) AS total_quantity,
        ISNULL(is.total_sales, 0.00) AS total_sales,
        ISNULL(is.total_orders, 0) AS total_orders
    FROM customer_details cd
    LEFT JOIN item_sales is ON cd.c_customer_sk = is.ws_item_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    email_length,
    total_quantity,
    total_sales,
    total_orders,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM sales_report
WHERE cd_gender = 'F' AND total_quantity > 5
ORDER BY total_sales DESC, full_name
LIMIT 100;
