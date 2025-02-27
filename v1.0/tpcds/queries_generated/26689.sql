
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ws.ws_order_number,
        w.w_warehouse_name,
        s.s_store_name,
        sa.full_address,
        ci.full_name
    FROM 
        store_sales ss
    JOIN 
        web_sales ws ON ss.ss_ticket_number = ws.ws_order_number
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        AddressDetails sa ON s.s_street_number = sa.ca_address_sk
    JOIN 
        CustomerInfo ci ON ss.ss_customer_sk = ci.c_customer_sk
)
SELECT 
    ci.full_name,
    COUNT(sd.ss_ticket_number) AS total_sales,
    SUM(sd.ss_quantity) AS total_quantity_sold,
    SUM(sd.ss_sales_price) AS total_revenue,
    MAX(sd.w_warehouse_name) AS preferred_warehouse,
    MAX(sd.s_store_name) AS preferred_store,
    STRING_AGG(DISTINCT sd.full_address) AS unique_addresses
FROM 
    SalesDetails sd
JOIN 
    CustomerInfo ci ON sd.full_name = ci.full_name
GROUP BY 
    ci.full_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
