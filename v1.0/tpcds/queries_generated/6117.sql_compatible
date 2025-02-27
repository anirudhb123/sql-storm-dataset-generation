
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.net_profit) DESC) AS rank_by_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_sk
),
top_websites AS (
    SELECT 
        w.warehouse_id,
        w.warehouse_name,
        rs.total_net_profit,
        rs.total_orders
    FROM 
        ranked_sales rs
    JOIN 
        warehouse w ON rs.web_site_sk = w.w_warehouse_sk
    WHERE 
        rs.rank_by_profit <= 5
)
SELECT 
    tw.warehouse_id, 
    tw.warehouse_name, 
    tw.total_net_profit, 
    tw.total_orders,
    CUME_DIST() OVER (ORDER BY tw.total_net_profit DESC) AS cumulative_distribution
FROM 
    top_websites tw
ORDER BY 
    tw.total_net_profit DESC;
