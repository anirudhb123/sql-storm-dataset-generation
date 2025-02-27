
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
DetailedInfo AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        si.total_sales,
        si.total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders,
    CASE 
        WHEN total_sales BETWEEN 0 AND 1000 THEN 'Low Value Customer'
        WHEN total_sales BETWEEN 1001 AND 5000 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS customer_type
FROM 
    DetailedInfo
ORDER BY 
    total_sales DESC
LIMIT 100;
