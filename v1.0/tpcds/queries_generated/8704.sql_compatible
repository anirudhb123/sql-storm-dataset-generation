
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_sales) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_addr_sk
    WHERE 
        d.d_year = 2022
        AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        d.d_year, d.d_month_seq, s.s_store_name
),
top_sales AS (
    SELECT 
        d_year,
        d_month_seq,
        s_store_name,
        total_quantity,
        total_sales,
        order_count,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    d_year,
    d_month_seq,
    s_store_name,
    total_quantity,
    total_sales,
    order_count
FROM 
    top_sales
WHERE 
    sales_rank <= 5
ORDER BY 
    d_year, d_month_seq, total_sales DESC;
