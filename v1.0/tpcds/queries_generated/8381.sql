
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND cd.cd_gender = 'F' 
    GROUP BY 
        ws.web_site_sk
),
TopWebSites AS (
    SELECT 
        w.w_warehouse_id,
        r.total_profit,
        r.total_orders
    FROM 
        RankedSales r
    JOIN 
        web_site w ON r.web_site_sk = w.web_site_sk
    WHERE 
        r.profit_rank <= 10
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    t.total_profit,
    t.total_orders,
    CAST(t.total_profit / NULLIF(t.total_orders, 0) AS DECIMAL(10,2)) AS avg_profit_per_order
FROM 
    TopWebSites t
JOIN 
    warehouse w ON w.w_warehouse_sk = t.web_site_sk
ORDER BY 
    t.total_profit DESC;
