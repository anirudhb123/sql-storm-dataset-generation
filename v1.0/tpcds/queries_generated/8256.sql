
WITH sales_data AS (
    SELECT 
        w.warehouse_name,
        c.c_city,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND (d.d_month_seq = 1 OR d.d_month_seq = 2) 
    GROUP BY 
        w.warehouse_name, c.c_city
),
ranked_sales AS (
    SELECT 
        warehouse_name, 
        c_city,
        total_quantity_sold,
        total_net_profit,
        total_orders,
        unique_customers,
        RANK() OVER (PARTITION BY c_city ORDER BY total_net_profit DESC) AS rank_by_profit
    FROM 
        sales_data
)
SELECT 
    warehouse_name, 
    c_city,
    total_quantity_sold,
    total_net_profit,
    total_orders,
    unique_customers
FROM 
    ranked_sales
WHERE 
    rank_by_profit <= 3
ORDER BY 
    c_city, total_net_profit DESC;
