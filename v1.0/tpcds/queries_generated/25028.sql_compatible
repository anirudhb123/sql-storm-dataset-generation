
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(c.c_birth_country, 'Unknown') AS birth_country,
        c.c_email_address,
        c.c_current_addr_sk,
        c.c_preferred_cust_flag
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ship_date_sk,
        d.d_date AS sale_date,
        ci.full_name,
        ci.ca_city,
        ci.ca_state
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
)
SELECT 
    sale_date,
    COUNT(DISTINCT full_name) AS unique_customers,
    SUM(ws_sales_price) AS total_sales,
    AVG(ws_sales_price) AS average_sale_amount,
    ca_state
FROM 
    SalesData
GROUP BY 
    sale_date, ca_state
ORDER BY 
    sale_date, total_sales DESC;
