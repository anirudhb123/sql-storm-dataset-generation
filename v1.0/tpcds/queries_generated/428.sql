
WITH RankedWebSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
HighestSellingItems AS (
    SELECT 
        ir.ws_item_sk,
        ir.total_quantity,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt
    FROM 
        RankedWebSales ir
    LEFT JOIN 
        CustomerReturns cr ON ir.ws_item_sk = cr.sr_item_sk
    WHERE 
        ir.rank_quantity <= 5
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    hi.total_quantity,
    hi.return_count,
    hi.total_return_amt,
    (hi.total_quantity - hi.return_count) AS net_sales,
    ROUND((hi.total_return_amt / NULLIF(hi.total_quantity, 0)) * 100, 2) AS return_rate_percentage
FROM 
    HighestSellingItems hi
JOIN 
    item i ON hi.ws_item_sk = i.i_item_sk
ORDER BY 
    total_quantity DESC;
