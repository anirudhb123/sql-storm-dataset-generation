
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_date = DATEADD(year, -1, GETDATE())
    )
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
TopItems AS (
    SELECT 
        r.ws_item_sk,
        r.ws_sales_price,
        r.ws_quantity,
        COALESCE(rt.total_returns, 0) AS total_returns,
        COALESCE(rt.total_returned_amt, 0) AS total_returned_amt
    FROM RankedSales r
    LEFT JOIN ReturnStats rt ON r.ws_item_sk = rt.sr_item_sk
    WHERE r.rn = 1
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.ws_sales_price,
    ti.ws_quantity,
    ti.total_returns,
    ti.total_returned_amt,
    (ti.ws_sales_price * ti.ws_quantity) - ti.total_returned_amt AS net_sales,
    CASE 
        WHEN ti.total_returns > 0 THEN 'Returned' 
        ELSE 'Sold' 
    END AS sales_status
FROM item i
JOIN TopItems ti ON i.i_item_sk = ti.ws_item_sk
ORDER BY net_sales DESC
LIMIT 50;
