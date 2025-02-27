
WITH item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_value,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
top_items AS (
    SELECT 
        i.i_item_id, 
        is.total_sold_quantity,
        is.total_sales_value,
        RANK() OVER (ORDER BY is.total_sales_value DESC) AS sales_rank
    FROM 
        item_sales is
    ORDER BY 
        is.total_sold_quantity DESC
    LIMIT 10
),
sales_by_category AS (
    SELECT 
        i.i_category,
        SUM(ws.ws_quantity) AS category_total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS category_total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_category
)
SELECT 
    t.top_items,
    t.total_sold_quantity,
    t.total_sales_value,
    sc.category_total_quantity,
    sc.category_total_sales
FROM 
    top_items t
JOIN 
    sales_by_category sc ON t.i_item_id = sc.i_category
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales_value DESC;
