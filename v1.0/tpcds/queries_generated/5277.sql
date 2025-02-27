
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        wd.d_year,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
        AVG(ws.ws_net_profit) AS average_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site wd ON ws.ws_web_site_sk = wd.web_site_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.web_site_id, wd.d_year
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_sales_quantity,
        total_sales_amount,
        average_net_profit,
        total_orders,
        RANK() OVER (ORDER BY total_sales_amount DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    t.web_site_id,
    t.total_sales_quantity,
    t.total_sales_amount,
    t.average_net_profit,
    t.total_orders
FROM 
    TopWebsites t
WHERE 
    t.sales_rank <= 5
ORDER BY 
    t.total_sales_amount DESC;
