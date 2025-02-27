
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        a.ca_city,
        a.ca_state,
        a.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
),
DeliveryMethods AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    ci.full_customer_name,
    ci.c_email_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    dm.sm_ship_mode_id,
    dm.order_count AS delivery_method_order_count
FROM 
    CustomerInfo ci
JOIN 
    SalesData sd ON ci.c_email_address LIKE '%' || sd.web_site_id || '%'
JOIN 
    DeliveryMethods dm ON sd.total_orders > 10
WHERE 
    ci.ca_city ILIKE '%new york%'
ORDER BY 
    sd.total_sales DESC, ci.full_customer_name ASC
LIMIT 100;
