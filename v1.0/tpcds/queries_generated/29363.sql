
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),

SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        c.c_customer_id,
        c.full_name,
        c.ca_city,
        c.ca_state
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_id
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk)
            FROM date_dim
            WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk)
            FROM date_dim
            WHERE d_year = 2023
        )
),

AggregatedSales AS (
    SELECT 
        full_name,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        STRING_AGG(DISTINCT CONCAT(ca_city, ', ', ca_state), '; ') AS locations
    FROM 
        SalesDetails
    GROUP BY 
        full_name
)

SELECT 
    *,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    AggregatedSales
ORDER BY 
    total_sales DESC;
