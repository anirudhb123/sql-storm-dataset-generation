
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CombinedStats AS (
    SELECT 
        rs.web_site_sk,
        rs.total_quantity,
        rs.total_profit,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        (rs.total_profit - COALESCE(cr.total_return_amt, 0)) AS net_profit_after_returns
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.web_site_sk = cr.wr_returning_customer_sk
)
SELECT 
    cs.web_site_sk,
    cs.total_quantity,
    cs.total_profit,
    cs.total_return_quantity,
    cs.total_return_amt,
    cs.net_profit_after_returns,
    CASE 
        WHEN cs.net_profit_after_returns > 0 THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS profitability
FROM 
    CombinedStats cs
WHERE 
    cs.rank = 1
ORDER BY 
    cs.net_profit_after_returns DESC
LIMIT 10;
