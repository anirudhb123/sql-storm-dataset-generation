
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30 -- Example date range
),
total_sales AS (
    SELECT
        ir.i_item_id,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales_amount
    FROM 
        ranked_sales rs
    JOIN 
        item ir ON rs.ws_item_sk = ir.i_item_sk
    WHERE 
        rs.sales_rank <= 10 -- Top 10 sales per item
    GROUP BY 
        ir.i_item_id
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    d.d_date,
    ts.total_sales_amount
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    total_sales ts ON ss.ss_item_sk = ts.ws_item_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    ts.total_sales_amount DESC
LIMIT 100;
