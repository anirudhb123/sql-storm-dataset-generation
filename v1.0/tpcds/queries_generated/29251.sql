
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
ItemInfo AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_current_price,
        i.i_category
    FROM item i
), 
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_billed_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_billed_customer_sk ORDER BY ws.ws_order_number DESC) AS OrderRank
    FROM web_sales ws
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ii.i_item_desc,
    ii.i_brand,
    SUM(si.ws_sales_price * si.ws_quantity) AS total_spent,
    COUNT(si.ws_order_number) AS total_orders
FROM CustomerInfo ci
JOIN SalesInfo si ON ci.c_customer_sk = si.ws_billed_customer_sk
JOIN ItemInfo ii ON si.ws_item_sk = ii.i_item_sk
WHERE si.OrderRank <= 5
GROUP BY 
    ci.full_name, 
    ci.ca_city, 
    ci.ca_state, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status, 
    ii.i_item_desc, 
    ii.i_brand
ORDER BY total_spent DESC
LIMIT 100;
