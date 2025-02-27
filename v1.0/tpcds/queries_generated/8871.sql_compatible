
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned, 
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rnk
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TopReturnedItems AS (
    SELECT
        ir.item_id,
        ir.item_desc,
        ir.i_current_price,
        rr.total_returned,
        rr.total_returned_amt
    FROM 
        RankedReturns rr
    JOIN 
        item ir ON rr.sr_item_sk = ir.i_item_sk
    WHERE 
        rr.rnk <= 10
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_sales_price) AS total_sales_amt
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    tri.item_id,
    tri.item_desc,
    tri.i_current_price,
    tri.total_returned,
    tri.total_returned_amt,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_sales_amt, 0) AS total_sales_amt,
    (tri.total_returned_amt / NULLIF(sd.total_sales_amt, 0)) * 100 AS return_rate_percentage
FROM 
    TopReturnedItems tri
LEFT JOIN 
    SalesData sd ON tri.sr_item_sk = sd.ws_item_sk
ORDER BY 
    tri.total_returned_amt DESC;
