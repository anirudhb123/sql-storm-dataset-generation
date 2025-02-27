
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        INITCAP(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        s.s_store_name,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_warehouse_sk = w.w_warehouse_sk
)
SELECT 
    a.ca_address_id,
    a.full_address,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    s.ws_order_number,
    s.ws_ext_sales_price,
    s.ws_net_profit,
    d.d_date AS sales_date
FROM 
    AddressDetails a
JOIN 
    CustomerDetails c ON c.c_customer_id = 'YOUR_CUSTOMER_ID'
JOIN 
    SalesDetails s ON s.ws_order_number IN (
        SELECT ss_order_number FROM store_sales WHERE ss_customer_sk = c.c_customer_sk
    )
JOIN 
    date_dim d ON s.ws_sold_date_sk = d.d_date_sk
WHERE 
    a.ca_city = 'YOUR_CITY' 
    AND a.ca_state = 'YOUR_STATE'
ORDER BY 
    s.ws_net_profit DESC;
