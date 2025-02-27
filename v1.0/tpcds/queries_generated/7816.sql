
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND 
        dd.d_month_seq <= 6
    GROUP BY 
        ws.web_site_id
),
top_websites AS (
    SELECT 
        web_site_id, 
        total_orders, 
        total_profit
    FROM 
        ranked_sales
    WHERE 
        profit_rank <= 10
)
SELECT 
    tw.web_site_id, 
    tw.total_orders, 
    tw.total_profit,
    dd.d_month AS sale_month
FROM 
    top_websites tw
JOIN 
    date_dim dd ON dd.d_year = 2022 AND dd.d_month_seq <= 6
ORDER BY 
    tw.total_profit DESC, 
    tw.total_orders DESC;
