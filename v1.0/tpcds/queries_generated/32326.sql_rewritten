WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_current_price, 1 AS level
    FROM item
    WHERE i_rec_start_date <= cast('2002-10-01' as date) AND i_rec_end_date >= cast('2002-10-01' as date)
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_current_price, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_brand_id = ih.i_item_sk 
    WHERE i_rec_start_date <= cast('2002-10-01' as date) AND i_rec_end_date >= cast('2002-10-01' as date)
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '30 days')
    AND (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date))
    GROUP BY ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '30 days')
    AND (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date))
    GROUP BY sr_item_sk
),
CombinedSales AS (
    SELECT 
        ih.i_item_id,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_returned_amount, 0) AS total_returned_amount,
        ih.level
    FROM ItemHierarchy ih
    LEFT JOIN SalesData sd ON ih.i_item_sk = sd.ws_item_sk
    LEFT JOIN ReturnData rd ON ih.i_item_sk = rd.sr_item_sk
)
SELECT 
    c.i_item_id,
    c.total_quantity,
    c.total_sales,
    c.total_returns,
    c.total_returned_amount,
    CASE 
        WHEN c.total_sales > 0 THEN (c.total_returns * 100.0 / c.total_sales) ELSE NULL 
    END AS return_percentage,
    ROW_NUMBER() OVER (PARTITION BY c.level ORDER BY c.total_sales DESC) AS sales_rank
FROM CombinedSales c
WHERE (c.total_sales > 1000 OR c.total_returns > 5)
ORDER BY c.level, return_percentage DESC;