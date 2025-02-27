
WITH ranked_sales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_quantity) DESC) AS sales_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cs_item_sk
),
inventory_summary AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
sales_and_inventory AS (
    SELECT 
        rs.cs_item_sk,
        rs.total_quantity,
        rs.total_sales,
        COALESCE(is.total_inventory, 0) AS total_inventory,
        CASE 
            WHEN is.total_inventory > 0 THEN (rs.total_sales / is.total_inventory)
            ELSE NULL 
        END AS sales_per_inventory
    FROM 
        ranked_sales rs
    LEFT JOIN 
        inventory_summary is ON rs.cs_item_sk = is.inv_item_sk
    WHERE 
        rs.sales_rank <= 10  -- Top 10 items by sales
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    sai.total_quantity,
    sai.total_sales,
    sai.total_inventory,
    sai.sales_per_inventory,
    COALESCE(sm.sm_type, 'Unknown') AS shipping_method
FROM 
    sales_and_inventory sai
JOIN 
    item i ON sai.cs_item_sk = i.i_item_sk
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT sr.ship_mode_sk 
                                           FROM store_returns sr 
                                           WHERE sr.sr_item_sk = i.i_item_sk 
                                           LIMIT 1)  -- Fetching shipping mode related to item
ORDER BY 
    sai.total_sales DESC
LIMIT 20;
