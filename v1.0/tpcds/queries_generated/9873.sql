
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year = 2023 AND 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        ws.web_site_sk, ws.ws_sales_price
),
TopWebSites AS (
    SELECT 
        web_site_sk, 
        total_quantity
    FROM 
        RankedSales
    WHERE 
        rank = 1
),
SalesSummary AS (
    SELECT
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_list_price) AS avg_list_price
    FROM 
        web_sales ws
    INNER JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN 
        TopWebSites tw ON ws.ws_web_site_sk = tw.web_site_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    ss.total_net_profit,
    ss.avg_list_price
FROM 
    SalesSummary ss
INNER JOIN 
    warehouse w ON ss.w_warehouse_id = w.w_warehouse_id
WHERE 
    ss.total_net_profit > 10000
ORDER BY 
    ss.total_net_profit DESC;
