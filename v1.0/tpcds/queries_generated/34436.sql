
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws.web_name
),
ReturnStats AS (
    SELECT 
        wr_item_sk,
        SUM(wr_net_loss) AS total_return_loss,
        COUNT(wr_order_number) AS total_returns
    FROM web_returns
    GROUP BY wr_item_sk
),
SalesReturnInfo AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        COALESCE(rs.total_return_loss, 0) AS total_return_loss,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (ws.ws_net_profit - COALESCE(rs.total_return_loss, 0)) AS net_profit_after_returns
    FROM web_sales ws
    LEFT JOIN ReturnStats rs ON ws.ws_item_sk = rs.wr_item_sk
)
SELECT 
    s.site_name,
    s.total_net_profit,
    COALESCE(SUM(sri.net_profit_after_returns), 0) AS adjusted_net_profit,
    CASE 
        WHEN s.total_net_profit > 500000 THEN 'High Performer'
        WHEN s.total_net_profit BETWEEN 100000 AND 500000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM SalesHierarchy s
LEFT JOIN SalesReturnInfo sri ON s.web_site_sk = sri.ws_web_site_sk
GROUP BY s.site_name, s.total_net_profit
HAVING adjusted_net_profit > 300000
ORDER BY adjusted_net_profit DESC;
