
WITH sales_summary AS (
    SELECT 
        ws.sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.sold_date_sk
),
top_items AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        total_profit DESC
    LIMIT 10
)
SELECT 
    s.sold_date_sk,
    s.total_quantity,
    s.total_sales,
    s.total_profit,
    ti.total_quantity_sold,
    ti.total_profit
FROM 
    sales_summary s
JOIN 
    top_items ti ON s.sold_date_sk = ti.ws_item_sk
ORDER BY 
    s.sold_date_sk;
