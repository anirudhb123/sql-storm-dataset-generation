
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
inventory_summary AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
sales_info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_addr_sk) AS unique_shipping_addresses
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
combined_info AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        is.total_quantity,
        si.total_sales,
        si.total_orders,
        si.unique_shipping_addresses
    FROM 
        customer_info ci
    LEFT JOIN 
        inventory_summary is ON is.inv_item_sk = ci.c_customer_sk
    LEFT JOIN 
        sales_info si ON si.ws_item_sk = ci.c_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    cd_purchase_estimate,
    cd_credit_rating,
    total_quantity,
    total_sales,
    total_orders,
    unique_shipping_addresses
FROM 
    combined_info
WHERE 
    total_sales > 1000 
    AND total_quantity > 5
ORDER BY 
    total_sales DESC, 
    total_quantity DESC;
