
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS Rank
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_manager IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr.returned_customer_sk,
        SUM(sr.return_quantity) AS total_returned_items,
        SUM(sr.return_amt) AS total_return_amount
    FROM store_returns sr
    GROUP BY sr.returned_customer_sk
),
TopPerformingSites AS (
    SELECT 
        rs.web_site_sk,
        SUM(rs.ws_net_profit) AS total_profit
    FROM RankedSales rs
    WHERE rs.Rank <= 3
    GROUP BY rs.web_site_sk
)
SELECT 
    w.web_site_id,
    COALESCE(tp.total_profit, 0) AS total_profit,
    COALESCE(cr.total_returned_items, 0) AS total_returned_items,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount
FROM web_site w
LEFT JOIN TopPerformingSites tp ON w.web_site_sk = tp.web_site_sk
LEFT JOIN CustomerReturns cr ON cr.returned_customer_sk IN (
    SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_web_site_sk = w.web_site_sk
)
WHERE w.web_open_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
ORDER BY total_profit DESC;
