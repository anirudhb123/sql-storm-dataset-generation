
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        i.i_item_desc,
        i.i_current_price,
        COALESCE((
            SELECT AVG(ss.ss_list_price)
            FROM store_sales ss
            WHERE ss.ss_item_sk = r.ws_item_sk
        ), 0) AS avg_store_price
    FROM 
        ranked_sales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank = 1
)
SELECT 
    ti.ws_item_sk,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.avg_store_price,
    CASE
        WHEN ti.total_sales > 50000 THEN 'High Performer'
        WHEN ti.total_sales BETWEEN 10000 AND 50000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    top_items ti
LEFT JOIN 
    customer c ON c.c_customer_sk = (
        SELECT c.c_customer_sk 
        FROM store_sales ss 
        WHERE ss.ss_item_sk = ti.ws_item_sk 
        ORDER BY ss.ss_sales_price DESC 
        LIMIT 1
    )
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' 
    AND ti.total_quantity > (
        SELECT AVG(total_quantity) FROM ranked_sales
    )
ORDER BY 
    ti.total_sales DESC;
