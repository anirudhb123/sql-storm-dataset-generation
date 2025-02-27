
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
address_data AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
), 
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales, 
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
), 
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
), 
final_data AS (
    SELECT 
        cd.c_customer_sk,
        ad.ca_city,
        ad.ca_state,
        sd.total_sales,
        sd.order_count,
        COALESCE(id.total_inventory, 0) AS inventory,
        cd.purchase_rank
    FROM customer_data cd
    JOIN address_data ad ON cd.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk = cd.c_current_cdemo_sk)
    LEFT JOIN sales_data sd ON cd.c_current_cdemo_sk = sd.ws_item_sk AND cd.purchase_rank <= 10
    LEFT JOIN inventory_data id ON cd.c_current_cdemo_sk = id.inv_item_sk
    WHERE ad.customer_count > 5
)

SELECT 
    fd.ca_city,
    fd.ca_state,
    COUNT(DISTINCT fd.c_customer_sk) AS customer_count,
    SUM(fd.total_sales) AS total_sales_sum,
    MAX(fd.inventory) AS max_inventory,
    MIN(fd.order_count) AS min_orders,
    AVG(fd.total_sales / NULLIF(fd.order_count, 0)) AS avg_sales_per_order
FROM final_data fd
GROUP BY fd.ca_city, fd.ca_state
HAVING 
    AVG(fd.total_sales / NULLIF(fd.order_count, 0)) > 100 
    AND MAX(fd.inventory) IS NOT NULL
ORDER BY total_sales_sum DESC
LIMIT 50;
