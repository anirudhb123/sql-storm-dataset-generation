
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS inventory_amount
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
item_ranking AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        RANK() OVER (ORDER BY i.i_current_price DESC) AS item_rank
    FROM item i
),
customer_sales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        SUM(cs.cs_quantity) AS total_store_quantity,
        SUM(cs.cs_ext_sales_price) AS total_store_sales,
        cs.cs_ship_mode_sk
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_order_number, cs.cs_ship_mode_sk
)
SELECT 
    i.i_item_id,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(sd.total_quantity) AS total_web_sales_quantity,
    SUM(cs.total_store_quantity) AS total_store_sales_quantity,
    COALESCE(SUM(sd.total_sales), 0) AS total_web_sales,
    COALESCE(SUM(cs.total_store_sales), 0) AS total_store_sales,
    COALESCE(SUM(iw.inventory_amount), 0) AS total_inventory,
    CASE 
        WHEN SUM(iw.inventory_amount) IS NULL THEN 'No Inventory' 
        WHEN SUM(iw.inventory_amount) < 10 THEN 'Low Inventory' 
        ELSE 'Sufficient Inventory' 
    END AS inventory_status,
    cd.value_category,
    STRING_AGG(DISTINCT cd.marital_status, ', ') AS marital_statuses
FROM item_ranking ir
JOIN sales_data sd ON ir.i_item_sk = sd.ws_item_sk
LEFT JOIN customer_sales cs ON ir.i_item_sk = cs.cs_item_sk
LEFT JOIN inventory_data iw ON ir.i_item_sk = iw.inv_item_sk
LEFT JOIN customer_data cd ON cs.cs_item_sk = cd.c_customer_sk
WHERE ir.item_rank <= 10 -- Only consider top 10 expensive items
GROUP BY 
    ir.i_item_id, cd.value_category
ORDER BY total_web_sales DESC, total_store_sales DESC
LIMIT 50;
