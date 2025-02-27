
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory,
        COALESCE(MAX(ws_ext_list_price), 0) AS max_web_price,
        COALESCE(MAX(cs_ext_list_price), 0) AS max_catalog_price,
        COALESCE(MAX(ss_ext_list_price), 0) AS max_store_price
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
sales_info AS (
    SELECT 
        is.i_item_sk,
        is.i_item_desc,
        rs.total_sales,
        is.total_inventory,
        is.max_web_price,
        is.max_catalog_price,
        is.max_store_price,
        (CASE 
            WHEN is.total_inventory = 0 THEN NULL 
            ELSE ROUND(rs.total_sales / is.total_inventory, 2) 
        END) AS sales_per_inventory
    FROM 
        item_summary is
    LEFT JOIN 
        ranked_sales rs ON is.i_item_sk = rs.ws_item_sk
)
SELECT 
    si.i_item_sk,
    si.i_item_desc,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.total_inventory, 0) AS total_inventory,
    COALESCE(si.max_web_price, 0) AS max_web_price,
    COALESCE(si.max_catalog_price, 0) AS max_catalog_price,
    COALESCE(si.max_store_price, 0) AS max_store_price,
    CASE 
        WHEN si.sales_per_inventory IS NULL THEN 'No Sales Data' 
        WHEN si.sales_per_inventory > 100 THEN 'High Sales Velocity' 
        WHEN si.sales_per_inventory BETWEEN 50 AND 100 THEN 'Medium Sales Velocity' 
        ELSE 'Low Sales Velocity' 
    END AS sales_velocity,
    si.sales_per_inventory
FROM 
    sales_info si
WHERE 
    si.total_inventory > 0
    AND (si.total_sales > 1000 OR si.max_web_price > 50)
ORDER BY 
    si.total_sales DESC;
