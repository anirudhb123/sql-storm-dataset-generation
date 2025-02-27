
WITH sales_data AS (
    SELECT 
        w.w_warehouse_name,
        s.s_store_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy BETWEEN 1 AND 12
    GROUP BY 
        w.w_warehouse_name, s.s_store_name
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    w_warehouse_name,
    s_store_name,
    total_quantity,
    total_sales,
    avg_profit,
    total_orders,
    sales_rank
FROM 
    ranked_sales
WHERE 
    sales_rank <= 5
ORDER BY 
    w_warehouse_name, sales_rank;
