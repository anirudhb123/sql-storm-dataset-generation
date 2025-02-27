
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND dd.d_month_seq IN (1, 2, 3)
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
TopSales AS (
    SELECT 
        web_site_sk,
        total_sales,
        unique_customers,
        avg_net_profit
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    w.web_site_id,
    ts.total_sales,
    ts.unique_customers,
    ts.avg_net_profit,
    w.web_manager
FROM 
    TopSales ts
JOIN 
    web_site w ON ts.web_site_sk = w.web_site_sk
ORDER BY 
    ts.total_sales DESC;
