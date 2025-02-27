
WITH RankedSales AS (
    SELECT 
        ws_date.d_year,
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim ws_date ON ws.ws_sold_date_sk = ws_date.d_date_sk
    GROUP BY 
        ws_date.d_year, ws.web_site_sk
),
TopWebSites AS (
    SELECT 
        web_site_sk, 
        total_net_profit, 
        total_orders
    FROM 
        RankedSales
    WHERE 
        rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(sr_ticket_number) AS total_returned_orders
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
)
SELECT 
    tws.web_site_sk,
    tws.total_net_profit,
    tws.total_orders,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_orders, 0) AS total_returned_orders,
    (tws.total_net_profit - COALESCE(cr.total_returned_quantity * (SELECT AVG(ws_ext_sales_price) FROM web_sales WHERE ws_item_sk IN (SELECT sr_item_sk FROM store_returns)), 0)) AS adjusted_net_profit
FROM 
    TopWebSites tws
LEFT JOIN 
    CustomerReturns cr ON tws.web_site_sk = cr.sr_returned_date_sk
ORDER BY 
    tws.total_net_profit DESC;
