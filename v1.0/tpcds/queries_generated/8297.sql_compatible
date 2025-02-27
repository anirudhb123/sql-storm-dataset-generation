
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        d.d_year = 2023 
        AND p.p_discount_active = 'Y'
    GROUP BY 
        ws.web_site_sk
),
ranked_sales AS (
    SELECT 
        web_site_sk,
        total_net_profit,
        total_orders,
        avg_sales_price,
        total_customers,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        sales_summary
)
SELECT 
    r.web_site_sk,
    w.web_name,
    r.total_net_profit,
    r.total_orders,
    r.avg_sales_price,
    r.total_customers,
    r.profit_rank
FROM 
    ranked_sales r
JOIN 
    web_site w ON r.web_site_sk = w.web_site_sk
WHERE 
    r.profit_rank <= 10
ORDER BY 
    r.profit_rank;
