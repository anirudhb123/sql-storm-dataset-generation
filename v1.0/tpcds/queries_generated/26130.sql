
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ss.total_sales,
        ss.total_orders
    FROM CustomerInfo ci
    LEFT JOIN SalesSummary ss ON ci.c_customer_id = ss.customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    ca_country,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM CombinedData
WHERE cd_gender = 'F'
ORDER BY total_sales DESC;
