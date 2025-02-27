
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        ws_item_sk,
        ws_order_number,
        1 AS sales_level
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk, ws_order_number
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        SUM(cs_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_quantity,
        cs_item_sk,
        cs_order_number,
        sales_level + 1
    FROM 
        catalog_sales
    JOIN 
        sales_data ON cs_item_sk = ws_item_sk
    GROUP BY 
        cs_sold_date_sk, cs_item_sk, cs_order_number
),
ranked_sales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.total_sales,
        sd.total_quantity,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
)
SELECT 
    ds.d_year,
    ds.d_month_seq,
    COUNT(DISTINCT rs.ws_item_sk) AS distinct_items,
    SUM(rs.total_sales) AS total_revenue,
    AVG(rs.total_quantity) AS avg_quantity_sold,
    (SUM(rs.total_sales) - SUM(rs.total_quantity * i.i_wholesale_cost)) AS net_profit
FROM 
    ranked_sales rs
JOIN 
    date_dim ds ON ds.d_date_sk = rs.ws_sold_date_sk
JOIN 
    item i ON i.i_item_sk = rs.ws_item_sk
WHERE 
    ds.d_year = 2023  
    AND rs.sales_rank <= 5
    AND (i.i_current_price IS NOT NULL AND i.i_current_price > 0)
GROUP BY 
    ds.d_year, ds.d_month_seq
ORDER BY 
    total_revenue DESC;
