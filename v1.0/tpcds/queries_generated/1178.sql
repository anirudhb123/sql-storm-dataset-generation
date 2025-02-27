
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_sk
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(wr_return_quantity) AS total_returns,
        AVG(wr_fee) AS average_return_fee
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesAndReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(rs.total_net_profit, 0) AS net_profit,
        COALESCE(cr.total_return_amount, 0) AS return_amount,
        COALESCE(cr.total_returns, 0) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        RankedSales rs ON c.c_customer_sk = rs.web_site_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
)
SELECT 
    s.c_customer_sk,
    s.net_profit,
    s.return_amount,
    s.total_returns,
    CASE 
        WHEN s.total_returns > 0 THEN s.return_amount / s.total_returns
        ELSE NULL 
    END AS average_return_per_item,
    RANK() OVER (ORDER BY s.net_profit DESC) AS customer_profit_rank
FROM 
    SalesAndReturns s
WHERE 
    s.net_profit > 1000
ORDER BY 
    s.customer_profit_rank
LIMIT 100;
