
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), inventory_check AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
), top_selling AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        i.total_inventory,
        CASE 
            WHEN i.total_inventory IS NULL THEN 'Out of Stock'
            WHEN i.total_inventory < s.total_quantity THEN 'Low Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        sales_cte s
    LEFT JOIN 
        inventory_check i ON s.ws_item_sk = i.inv_item_sk
    WHERE 
        s.rank <= 10
)
SELECT 
    t.ws_item_sk,
    t.total_quantity,
    t.total_sales,
    COALESCE(t.total_inventory, 0) AS total_inventory,
    t.stock_status,
    CONCAT(t.total_quantity, ' units sold at $', ROUND(t.total_sales, 2)) AS sales_description
FROM 
    top_selling t
ORDER BY 
    t.total_sales DESC;

WITH color_analysis AS (
    SELECT 
        i.i_item_sk,
        i.i_color,
        COUNT(cs.cs_order_number) AS color_sales_count
    FROM 
        item i
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY 
        i.i_item_sk, i.i_color
), color_summary AS (
    SELECT 
        i_color,
        SUM(color_sales_count) AS total_color_sales
    FROM 
        color_analysis
    GROUP BY 
        i_color
)
SELECT 
    c.i_color,
    c.total_color_sales,
    CASE 
        WHEN c.total_color_sales >= (
            SELECT AVG(total_color_sales) FROM color_summary
        ) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    color_summary c
ORDER BY 
    c.total_color_sales DESC;
