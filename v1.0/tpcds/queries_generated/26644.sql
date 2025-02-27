
WITH AddressData AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
), 
CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.full_address,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressData ca ON c.c_current_addr_sk = ca.ca_address_id
), 
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ship_date_sk,
        dd.d_date,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        CustomerData cd ON ws.ws_bill_customer_sk = cd.c_customer_id
)
SELECT 
    COUNT(*) AS total_sales,
    SUM(ws_sales_price) AS total_revenue,
    AVG(ws_sales_price) AS avg_sales_price,
    MIN(ws_sales_price) AS min_sales_price,
    MAX(ws_sales_price) AS max_sales_price,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    SalesData
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_revenue DESC
LIMIT 10;
