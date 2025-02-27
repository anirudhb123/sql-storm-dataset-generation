
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
InventorySummary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_current_price
    FROM item i
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    id.i_item_desc,
    id.i_brand,
    id.i_category,
    id.i_current_price,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.order_count, 0) AS order_count,
    COALESCE(inv.total_quantity, 0) AS total_inventory
FROM CustomerInfo ci
JOIN ItemDetails id ON 1=1  -- Cross join for benchmark purpose
LEFT JOIN SalesData si ON id.i_item_sk = si.ws_item_sk
LEFT JOIN InventorySummary inv ON id.i_item_sk = inv.inv_item_sk
WHERE ci.cd_gender = 'F' AND ci.cd_marital_status = 'M'
ORDER BY total_sales DESC, ci.full_name;
