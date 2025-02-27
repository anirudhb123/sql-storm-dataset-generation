
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_reason_sk,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
    GROUP BY 
        ws_item_sk
),
DetailedReturns AS (
    SELECT 
        r.reason_desc,
        cr.sr_item_sk,
        cr.sr_return_quantity,
        sd.total_sales,
        sd.total_profit,
        CASE 
            WHEN sd.total_sales IS NULL THEN 'No Sales'
            WHEN cr.sr_return_quantity > (sd.total_sales * 0.1) THEN 'High Return'
            ELSE 'Normal Return'
        END AS return_class
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        reason r ON cr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN 
        SalesData sd ON cr.sr_item_sk = sd.ws_item_sk
    WHERE 
        cr.return_rank = 1
)
SELECT 
    d.reason_desc,
    COUNT(DISTINCT dr.sr_item_sk) AS items_count,
    AVG(dr.total_sales) AS avg_sales,
    SUM(dr.total_profit) AS total_profit,
    MAX(dr.return_quantity) AS max_return_qty,
    MIN(dr.return_quantity) AS min_return_qty
FROM 
    DetailedReturns dr
GROUP BY 
    d.reason_desc
HAVING 
    SUM(dr.total_profit) > (
        SELECT AVG(total_profit) FROM SalesData
    )
ORDER BY 
    total_profit DESC
OFFSET 1 ROWS FETCH NEXT 5 ROWS ONLY;
