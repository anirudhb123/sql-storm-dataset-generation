
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city, 
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
ItemInfo AS (
    SELECT 
        i.i_item_sk,
        UPPER(i.i_item_desc) AS item_description,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
)
SELECT 
    ci.full_name,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_quantity) AS total_items_ordered,
    AVG(i.i_current_price) AS avg_item_price,
    LISTAGG(DISTINCT i.item_description, ', ') AS item_descriptions,
    CASE 
        WHEN ci.cd_gender = 'M' THEN 'Male'
        WHEN ci.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_desc,
    COUNT(DISTINCT ci.ca_state) AS unique_states
FROM 
    CustomerInfo ci
JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    ItemInfo i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ci.ca_city IS NOT NULL AND 
    ci.ca_state IS NOT NULL
GROUP BY 
    ci.full_name, 
    ci.cd_gender,
    ci.ca_city,
    ci.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 1
ORDER BY 
    total_items_ordered DESC;
