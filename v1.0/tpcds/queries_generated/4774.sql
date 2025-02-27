
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
TopWebSites AS (
    SELECT 
        web_site_sk,
        total_quantity,
        total_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 5
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        AVG(NULLIF(ws.ws_net_profit, 0)) AS avg_profit_per_order
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    wa.w_warehouse_name,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
    COALESCE(SUM(cs.cs_net_profit), 0) AS total_net_profit,
    COALESCE(AVG(NULLIF(cs.cs_net_profit, 0)), 0) AS avg_net_profit
FROM 
    warehouse wa
LEFT JOIN 
    catalog_sales cs ON wa.w_warehouse_sk = cs.cs_warehouse_sk
LEFT JOIN 
    TopWebSites tw ON cs.cs_bill_customer_sk = tw.web_site_sk
GROUP BY 
    wa.w_warehouse_name
ORDER BY 
    avg_net_profit DESC
LIMIT 10;
