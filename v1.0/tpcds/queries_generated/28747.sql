
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(CAST(cd.cd_dep_count AS VARCHAR), '0') || ' dependents' AS dependents,
        COALESCE(cd.cd_birth_year, 1970) AS birth_year
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS city_state_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
transaction_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        item.i_item_desc,
        ws.ws_net_paid,
        COALESCE(w.w_warehouse_name, 'Unknown') AS warehouse_name
    FROM 
        web_sales ws
    JOIN 
        item ON ws.ws_item_sk = item.i_item_sk
    LEFT JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.dependents,
    ai.full_address,
    ai.city_state_zip,
    ai.ca_country,
    SUM(td.ws_quantity) AS total_items_purchased,
    SUM(td.ws_net_paid) AS total_spent,
    COUNT(td.ws_order_number) AS total_orders,
    STRING_AGG(DISTINCT td.i_item_desc, ', ') AS items_purchased,
    ROW_NUMBER() OVER (PARTITION BY ci.c_customer_id ORDER BY SUM(td.ws_net_paid) DESC) AS purchase_rank
FROM 
    customer_info ci
JOIN 
    address_info ai ON ci.c_customer_id = ai.ca_address_id
LEFT JOIN 
    transaction_data td ON ci.c_customer_id = td.ws_order_number
GROUP BY 
    ci.c_customer_id, ci.full_name, ci.cd_gender, ci.dependents, 
    ai.full_address, ai.city_state_zip, ai.ca_country
ORDER BY 
    total_spent DESC
LIMIT 100;
