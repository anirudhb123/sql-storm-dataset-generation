
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2020
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_sales,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name
    FROM 
        ranked_sales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON c.c_customer_sk IN (
            SELECT 
                DISTINCT ws_bill_customer_sk 
            FROM 
                web_sales 
            WHERE 
                ws_item_sk = ri.ws_item_sk
        )
    WHERE 
        ri.sales_rank <= 10
)
SELECT 
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    CONCAT(ti.c_first_name, ' ', ti.c_last_name) AS customer_name
FROM 
    top_items ti
ORDER BY 
    ti.total_sales DESC;
