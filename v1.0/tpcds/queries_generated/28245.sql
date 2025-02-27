
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
OrderDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_sales_price,
        ws.ws_quantity,
        wi.i_item_desc,
        sm.sm_type AS shipping_method
    FROM 
        web_sales ws
    JOIN 
        item wi ON ws.ws_item_sk = wi.i_item_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
CombinedData AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        od.ws_order_number,
        od.ws_net_paid,
        od.ws_sales_price,
        od.ws_quantity,
        od.i_item_desc,
        od.shipping_method
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        OrderDetails od ON ci.c_customer_id = od.ws_order_number
)
SELECT 
    cd.ca_city,
    cd.ca_state,
    COUNT(*) AS total_orders,
    SUM(od.ws_net_paid) AS total_revenue,
    AVG(od.ws_sales_price) AS average_sales_price,
    MAX(od.ws_quantity) AS max_quantity_sold,
    MIN(od.ws_quantity) AS min_quantity_sold,
    STRING_AGG(DISTINCT od.shipping_method) AS unique_shipping_methods,
    COUNT(DISTINCT od.ws_order_number) AS distinct_order_count
FROM 
    CombinedData cd
JOIN 
    OrderDetails od ON cd.ws_order_number = od.ws_order_number
WHERE 
    cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
GROUP BY 
    cd.ca_city, cd.ca_state
ORDER BY 
    total_orders DESC;
