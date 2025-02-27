
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(ws2.ws_sold_date_sk) FROM web_sales ws2)
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_net_loss) AS total_return_loss
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.ws_net_profit,
        COALESCE(cr.total_return_loss, 0) AS total_return_loss
    FROM RankedSales rs
    LEFT JOIN CustomerReturns cr ON rs.ws_order_number = cr.wr_returning_customer_sk
)
SELECT 
    w.warehouse_name,
    SUM(sws.ws_net_profit) AS total_profit,
    AVG(sws.total_return_loss) AS average_return_loss
FROM SalesWithReturns sws
JOIN warehouse w ON sws.web_site_sk = w.w_warehouse_sk
WHERE sws.ws_net_profit > 0 
GROUP BY w.warehouse_name
HAVING AVG(sws.total_return_loss) < 1000
ORDER BY total_profit DESC
LIMIT 10;
