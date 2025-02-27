
WITH recent_sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
), 
top_items AS (
    SELECT
        rs.ws_item_sk,
        rs.total_quantity,
        ROW_NUMBER() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM 
        recent_sales rs
    WHERE 
        rs.total_quantity > 100
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(CAST(i.i_current_price AS DECIMAL(10, 2)), 0) AS current_price,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'N/A'
            ELSE 'Available' 
        END AS price_status
    FROM
        item i
)
SELECT
    itd.i_item_id,
    itd.i_product_name,
    tid.total_quantity,
    tid.total_sales,
    itd.current_price,
    itd.price_status
FROM
    top_items tid
LEFT JOIN 
    item_details itd ON tid.ws_item_sk = itd.i_item_sk
WHERE
    tid.sales_rank <= 10 
ORDER BY 
    tid.total_sales DESC;
