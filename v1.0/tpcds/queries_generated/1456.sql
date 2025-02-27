
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.customer_sk,
        sr.return_item_sk,
        SUM(sr.return_quantity) AS total_returned_qty,
        SUM(sr.return_amt) AS total_returned_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk, sr.return_time_sk, sr.customer_sk, sr.return_item_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_qty,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
LatestReturns AS (
    SELECT 
        cr.returning_customer_sk,
        cr.return_item_sk,
        COALESCE(cr.total_returned_qty, 0) AS returned_qty,
        COALESCE(sd.total_sold_qty, 0) AS sold_qty,
        COALESCE(sd.total_net_profit, 0) AS net_profit
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        SalesData sd ON cr.customer_sk = sd.ws_sold_date_sk AND cr.return_item_sk = sd.ws_item_sk
),
CustomerStats AS (
    SELECT 
        r.returning_customer_sk,
        r.return_item_sk,
        r.returned_qty,
        r.sold_qty,
        CASE 
            WHEN r.sold_qty > 0 THEN (r.returned_qty::decimal / r.sold_qty) * 100 
            ELSE NULL 
        END AS return_rate,
        r.net_profit
    FROM 
        LatestReturns r
)

SELECT 
    cs.returning_customer_sk,
    cs.return_item_sk,
    cs.returned_qty,
    cs.sold_qty,
    cs.return_rate,
    cs.net_profit,
    CASE 
        WHEN cs.return_rate > 10 THEN 'High'
        WHEN cs.return_rate BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Low' 
    END AS return_class
FROM 
    CustomerStats cs
WHERE 
    cs.returned_qty > 0
ORDER BY 
    cs.return_rate DESC
LIMIT 50;
