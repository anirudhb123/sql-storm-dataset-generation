
WITH sales_summary AS (
    SELECT 
        d.d_year, 
        d.d_quarter_seq, 
        s.s_store_name, 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_value,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_addr_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_year, d.d_quarter_seq, s.s_store_name, i.i_item_id
),
top_sales AS (
    SELECT 
        d_year, 
        d_quarter_seq, 
        s_store_name, 
        i_item_id, 
        total_quantity_sold, 
        total_sales_value, 
        avg_sales_price,
        RANK() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY total_sales_value DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    d_year,
    d_quarter_seq,
    s_store_name,
    i_item_id,
    total_quantity_sold,
    total_sales_value,
    avg_sales_price
FROM 
    top_sales
WHERE 
    sales_rank <= 5
ORDER BY 
    d_year, 
    d_quarter_seq, 
    total_sales_value DESC;
