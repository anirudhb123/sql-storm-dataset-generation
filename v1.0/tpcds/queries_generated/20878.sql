
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid_inc_tax IS NOT NULL 
        AND ws.ws_quantity > 0
), 
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns 
    WHERE 
        sr_return_quantity > 0 
    GROUP BY 
        sr_item_sk
), 
SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        rs.total_profit
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.sr_item_sk
)
SELECT 
    swr.ws_item_sk,
    swr.ws_sales_price,
    swr.total_profit,
    swr.return_count,
    swr.total_return_amount,
    CASE 
        WHEN total_profit < 0 THEN 'Unprofitable'
        WHEN total_return_amount > total_profit THEN 'High Return Risk'
        ELSE 'Stable'
    END AS status,
    CASE 
        WHEN swr.return_count > 0 THEN 
            (SELECT COUNT(DISTINCT wr_order_number) 
             FROM web_returns wr 
             WHERE wr.wr_item_sk = swr.ws_item_sk 
             AND wr.wr_return_qty > 0)
        ELSE 0 
    END AS distinct_web_return_orders
FROM 
    SalesWithReturns swr
WHERE 
    swr.return_count IS NOT NULL
ORDER BY 
    swr.total_profit DESC, 
    swr.ws_sales_price ASC;
