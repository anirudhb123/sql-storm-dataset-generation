
WITH RECURSIVE sales_tree AS (
    SELECT 
        ws_item_sk, 
        ws_sales_price,
        ws_quantity, 
        1 as lvl
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT 
        cs_item_sk, 
        cs_sales_price,
        cs_quantity, 
        lvl + 1
    FROM 
        catalog_sales
    WHERE 
        cs_order_number IN (SELECT ws_order_number FROM web_sales)
        AND lvl < 5
)
, inventory_summary AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    item.i_item_id,
    item.i_product_name,
    item.i_current_price,
    COALESCE(ws.total_sales_price, 0) AS total_web_sales,
    COALESCE(cs.total_catalog_sales_price, 0) AS total_catalog_sales,
    inv.total_inventory,
    RANK() OVER (PARTITION BY item.i_item_id ORDER BY COALESCE(ws.total_sales_price, 0) + COALESCE(cs.total_catalog_sales_price, 0) DESC) AS sales_rank
FROM 
    item 
LEFT JOIN (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price * ws_quantity) AS total_sales_price 
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
) ws ON item.i_item_sk = ws.ws_item_sk
LEFT JOIN (
    SELECT 
        cs_item_sk, 
        SUM(cs_sales_price * cs_quantity) AS total_catalog_sales_price 
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
) cs ON item.i_item_sk = cs.cs_item_sk
LEFT JOIN 
    inventory_summary inv ON item.i_item_sk = inv.inv_item_sk
WHERE 
    (COALESCE(ws.total_sales_price, 0) > 1000 OR COALESCE(cs.total_catalog_sales_price, 0) > 1000)
    AND (item.i_current_price IS NOT NULL AND item.i_current_price > 0)
ORDER BY 
    sales_rank
LIMIT 50;
