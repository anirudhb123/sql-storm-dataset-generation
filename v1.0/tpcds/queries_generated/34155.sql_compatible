
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        0 AS level
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        ss.total_quantity + cs.cs_quantity,
        ss.total_sales + cs.cs_sales_price,
        1 AS level
    FROM 
        sales_summary ss
    JOIN 
        catalog_sales cs ON ss.ws_item_sk = cs.cs_item_sk
    WHERE 
        ss.level < 1
),
max_sales AS (
    SELECT 
        ws_item_sk,
        MAX(total_sales) AS max_sales
    FROM 
        sales_summary
    GROUP BY 
        ws_item_sk
),
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ca.ca_address_id,
    SUM(ms.max_sales) AS grand_total_sales,
    CASE 
        WHEN i.total_inventory IS NULL THEN 'Out of Stock'
        WHEN i.total_inventory < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    customer_address ca
LEFT JOIN 
    web_sales ws ON ca.ca_address_sk = ws.ws_ship_addr_sk
LEFT JOIN 
    max_sales ms ON ws.ws_item_sk = ms.ws_item_sk
LEFT JOIN 
    inventory_status i ON ws.ws_item_sk = i.inv_item_sk
GROUP BY 
    ca.ca_address_id, i.total_inventory
HAVING 
    SUM(ms.max_sales) > (SELECT AVG(max_sales) FROM max_sales)
ORDER BY 
    grand_total_sales DESC
FETCH FIRST 10 ROWS ONLY;
