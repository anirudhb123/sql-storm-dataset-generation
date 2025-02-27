
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.net_paid_inc_tax) AS avg_order_value,
        d.year AS sales_year,
        d.month AS sales_month
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.sold_date_sk = d.date_sk
    JOIN 
        customer c ON ws.bill_customer_sk = c.customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    WHERE 
        d.year = 2023 AND 
        cd.credit_rating = 'Good'
    GROUP BY 
        ws.web_site_sk, 
        d.year, 
        d.month
), ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY sales_year, sales_month ORDER BY total_net_profit DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    ws.warehouse_id, 
    ws.total_net_profit, 
    ws.total_orders, 
    ws.avg_order_value, 
    ws.sales_year, 
    ws.sales_month
FROM 
    ranked_sales ws
JOIN 
    warehouse w ON ws.web_site_sk = w.warehouse_sk
WHERE 
    ws.sales_rank <= 5
ORDER BY 
    ws.sales_year, ws.sales_month, ws.total_net_profit DESC;
