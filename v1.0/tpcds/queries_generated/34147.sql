
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
),
AggregatedSales AS (
    SELECT 
        web_site_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        MAX(ws_sales_price) AS max_sales_price,
        MIN(ws_sales_price) AS min_sales_price
    FROM SalesData
    GROUP BY web_site_id
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_net_loss) AS total_loss
    FROM web_returns
    GROUP BY wr_returning_customer_sk
)
SELECT 
    a.web_site_id,
    a.total_quantity,
    a.total_net_profit,
    a.max_sales_price,
    a.min_sales_price,
    COALESCE(c.total_returns, 0) AS total_returns,
    COALESCE(c.total_loss, 0) AS total_loss,
    CASE 
        WHEN a.total_net_profit > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability,
    CASE 
        WHEN a.total_quantity = 0 THEN NULL
        ELSE ROUND(COALESCE(c.total_returns, 0) * 100.0 / a.total_quantity, 2)
    END AS return_rate_percentage
FROM AggregatedSales a
LEFT JOIN CustomerReturns c ON a.web_site_id = c.wr_returning_customer_sk
ORDER BY a.total_net_profit DESC, a.total_quantity DESC
LIMIT 10;
