
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ', ', ca.ca_zip) AS address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        dd.d_date AS sale_date,
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY c.cd_marital_status ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_id
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
)
SELECT 
    full_name,
    SUM(ws_sales_price) AS total_spent,
    COUNT(ws_order_number) AS total_orders,
    MAX(sale_date) AS last_purchase_date,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate
FROM 
    SalesInfo
WHERE 
    rank <= 10
GROUP BY 
    full_name, cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate
ORDER BY 
    total_spent DESC;
