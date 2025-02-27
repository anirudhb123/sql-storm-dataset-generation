
WITH sales_summary AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year = 2023 
        AND ws.ws_net_profit > 0
    GROUP BY 
        ws.web_site_id
),
top_websites AS (
    SELECT 
        w.web_site_id, 
        s.total_net_profit,
        s.total_orders,
        s.avg_order_value,
        s.unique_customers,
        DENSE_RANK() OVER (ORDER BY s.total_net_profit DESC) AS rank
    FROM 
        sales_summary s
    JOIN 
        web_site w ON s.web_site_id = w.web_site_id
)
SELECT 
    tw.web_site_id,
    tw.total_net_profit,
    tw.total_orders,
    tw.avg_order_value,
    tw.unique_customers
FROM 
    top_websites tw
WHERE 
    tw.rank <= 5
ORDER BY 
    tw.total_net_profit DESC;
