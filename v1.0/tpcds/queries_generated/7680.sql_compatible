
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq
),
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity_sold,
        ss.total_sales,
        ss.total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.d_year ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity_sold,
    ts.total_sales,
    ts.total_profit,
    d.d_year,
    d.d_month_seq
FROM 
    top_sales ts
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ts.d_year = d.d_year
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    d.d_year, ts.total_sales DESC;
