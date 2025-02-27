
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name || ' ' || c_last_name AS full_name,
        NULL AS parent_customer_sk,
        0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        ch.c_customer_sk AS parent_customer_sk,
        ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
)

, sales_by_customer AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer_hierarchy ch ON ws.bill_customer_sk = ch.c_customer_sk
    GROUP BY ws.bill_customer_sk
)

SELECT 
    ch.full_name,
    COALESCE(sbc.total_sales, 0) AS total_sales,
    sbc.order_count,
    ch.level
FROM customer_hierarchy ch
LEFT JOIN sales_by_customer sbc ON ch.c_customer_sk = sbc.bill_customer_sk
WHERE ch.level < 3
ORDER BY ch.level, total_sales DESC;

WITH inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouses_count
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),

items_with_sales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sold,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_sales_value
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
)

SELECT 
    iw.i_item_id,
    iw.i_item_desc,
    COALESCE(iv.total_quantity, 0) AS quantity_in_stock,
    iw.total_sold,
    iw.total_sales_value,
    CASE 
        WHEN iw.total_sales_value IS NULL THEN 'No Sales'
        WHEN iw.total_sales_value > 10000 THEN 'High Revenue'
        ELSE 'Moderate Revenue'
    END AS revenue_category
FROM items_with_sales iw
LEFT JOIN inventory_data iv ON iw.i_item_id = iv.inv_item_sk
WHERE (iv.warehouses_count IS NULL OR iv.warehouses_count > 5)
ORDER BY iw.total_sales_value DESC 
LIMIT 100;
