
WITH RECURSIVE ItemHierarchy AS (
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, 0 AS depth
    FROM item i
    WHERE i.i_item_sk = 1 -- Starting point for recursion
    UNION ALL
    SELECT i2.i_item_sk, i2.i_item_id, i2.i_item_desc, i2.i_current_price, ih.depth + 1
    FROM item i2
    JOIN ItemHierarchy ih ON i2.i_brand_id = ih.i_item_sk -- Example relationship for recursion
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count
    FROM web_sales ws
    GROUP BY ws.ws_order_number
),
IncompleteReturns AS (
    SELECT 
        sr.store_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amt
    FROM store_returns sr
    GROUP BY sr.store_sk
),
SalesSummary AS (
    SELECT 
        d.d_year,
        sd.ws_order_number,
        sd.total_sales,
        ir.total_returns,
        ir.total_return_amt
    FROM SalesData sd
    JOIN store s ON sd.ws_order_number = s.s_store_sk
    JOIN date_dim d ON s.s_rec_start_date = d.d_date
    LEFT JOIN IncompleteReturns ir ON s.s_store_sk = ir.store_sk
)
SELECT 
    ih.i_item_desc,
    ss.d_year,
    ss.total_sales,
    ss.total_returns,
    ss.total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY ss.d_year ORDER BY ss.total_sales DESC) as sales_rank,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales > 10000 THEN 'High Sales'
        ELSE 'Moderate Sales'
    END AS sales_category
FROM ItemHierarchy ih
JOIN SalesSummary ss ON ih.i_item_sk = ss.ws_order_number
WHERE ss.total_sales > 5000
ORDER BY ss.d_year, ss.total_sales DESC;
