
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        sr.return_amt_inc_tax,
        sr.return_ship_cost,
        sr.refunded_cash,
        sr.reversed_charge,
        sr.store_credit,
        sr.net_loss,
        ROW_NUMBER() OVER (PARTITION BY sr.item_sk ORDER BY sr.returned_date_sk DESC) AS rn
    FROM 
        store_returns sr
    WHERE 
        sr.returned_date_sk BETWEEN 20230101 AND 20231231
),
TopReturns AS (
    SELECT 
        rr.returned_date_sk,
        rr.return_time_sk,
        rr.item_sk,
        rr.return_quantity,
        rr.return_amt,
        rr.return_tax,
        rr.return_amt_inc_tax,
        rr.return_ship_cost,
        rr.refunded_cash,
        rr.reversed_charge,
        rr.store_credit,
        rr.net_loss
    FROM 
        RankedReturns rr
    WHERE 
        rr.rn = 1
),
SalesData AS (
    SELECT 
        ws.item_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(ws.order_number) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        TopReturns tr ON ws.item_sk = tr.item_sk
    GROUP BY 
        ws.item_sk
)
SELECT 
    i.item_id,
    i.item_desc,
    sd.total_net_profit,
    sd.total_sales,
    COUNT(tr.return_quantity) AS total_returns,
    SUM(tr.return_amt) AS total_return_amount,
    AVG(tr.return_tax) AS avg_return_tax,
    AVG(tr.return_ship_cost) AS avg_return_ship_cost
FROM 
    item i
JOIN 
    SalesData sd ON i.item_sk = sd.item_sk
LEFT JOIN 
    TopReturns tr ON i.item_sk = tr.item_sk
GROUP BY 
    i.item_id, i.item_desc, sd.total_net_profit, sd.total_sales
ORDER BY 
    total_net_profit DESC
LIMIT 10;
