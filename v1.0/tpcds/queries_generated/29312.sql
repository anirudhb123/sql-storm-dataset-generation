
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemInfo AS (
    SELECT 
        i.i_item_sk,
        LOWER(i.i_item_desc) AS item_description,
        i.i_brand,
        i.i_category,
        i.i_current_price
    FROM item i
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
Benchmarking AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        si.item_description,
        si.i_brand,
        si.i_current_price,
        ss.total_quantity,
        ss.total_sales
    FROM CustomerInfo ci
    JOIN SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    JOIN ItemInfo si ON si.i_item_sk = ss.ws_item_sk
    WHERE 
        ci.cd_gender = 'F' AND
        ss.total_quantity > 0 
    ORDER BY ss.total_sales DESC
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    item_description,
    i_brand,
    i_current_price,
    total_quantity,
    total_sales,
    ROUND((total_sales / NULLIF(total_quantity, 0)), 2) AS avg_sales_per_item
FROM Benchmarking
LIMIT 100;
