
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        wd.customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY wd.customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        customer wd ON ws.ws_bill_customer_sk = wd.c_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_id, wd.customer_id
)
SELECT 
    rs.web_site_id,
    rs.customer_id,
    rs.total_quantity,
    rs.total_net_profit,
    rs.total_orders
FROM 
    RankedSales rs
WHERE 
    rs.rnk <= 5
ORDER BY 
    rs.total_net_profit DESC;
