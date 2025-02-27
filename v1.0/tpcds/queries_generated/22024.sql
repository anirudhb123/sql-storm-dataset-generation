
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_quantity) DESC) AS site_rank
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
top_sites AS (
    SELECT 
        web_site_sk,
        web_site_id
    FROM 
        ranked_sales
    WHERE 
        site_rank <= 5
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_price,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price
    FROM 
        web_sales ws
    JOIN 
        top_sites ts ON ws.ws_web_site_sk = ts.web_site_sk
    GROUP BY 
        ws.ws_item_sk
),
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        CASE 
            WHEN SUM(inv.inv_quantity_on_hand) < 50 THEN 'Low'
            WHEN SUM(inv.inv_quantity_on_hand) BETWEEN 50 AND 150 THEN 'Medium'
            ELSE 'High'
        END AS inventory_level
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    is.total_sales,
    is.avg_price,
    is.max_price,
    is.min_price,
    inv.total_inventory,
    inv.inventory_level
FROM 
    item i
JOIN 
    item_sales is ON i.i_item_sk = is.ws_item_sk
LEFT JOIN 
    inventory_status inv ON i.i_item_sk = inv.inv_item_sk
WHERE 
    inv.inventory_level IS NOT NULL
    AND (is.total_sales >= 100 OR inv.total_inventory < 100) 
ORDER BY 
    total_sales DESC,
    avg_price ASC;
