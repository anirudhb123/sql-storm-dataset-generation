
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ci.full_name,
        ci.ca_city,
        ci.ca_state
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
),
AggregatedSales AS (
    SELECT
        full_name,
        ca_city,
        ca_state,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM 
        SalesData
    GROUP BY 
        full_name, ca_city, ca_state
)
SELECT
    full_name,
    ca_city,
    ca_state,
    total_orders,
    total_sales,
    total_quantity,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value' 
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    AggregatedSales
WHERE 
    total_orders > 5
ORDER BY 
    total_sales DESC;
