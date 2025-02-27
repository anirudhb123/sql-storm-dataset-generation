
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rk
    FROM 
        web_sales ws
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_count
    FROM 
        web_returns
    WHERE 
        wr_return_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        wr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_sales_price,
        rs.ws_net_profit,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.return_count, 0) AS return_count
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.web_site_sk = cr.wr_returning_customer_sk
)
SELECT 
    swr.web_site_sk,
    swr.ws_order_number,
    swr.ws_item_sk,
    swr.ws_quantity,
    swr.ws_sales_price,
    swr.ws_net_profit,
    swr.total_return_amt,
    swr.return_count
FROM 
    SalesWithReturns swr
WHERE 
    swr.ws_net_profit > (SELECT AVG(ws_net_profit) FROM web_sales)
    AND swr.total_return_amt < (swr.ws_sales_price * 0.1)
ORDER BY 
    swr.ws_net_profit DESC
LIMIT 100;
