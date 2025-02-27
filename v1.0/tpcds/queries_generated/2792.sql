
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2453480 AND 2453848
),
CustomerReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM web_returns
    GROUP BY wr_item_sk
),
TotalSales AS (
    SELECT
        item.i_item_sk,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales_amount,
        COALESCE(cr.total_returned, 0) AS total_returned
    FROM item
    LEFT JOIN web_sales ws ON item.i_item_sk = ws.ws_item_sk
    LEFT JOIN CustomerReturns cr ON item.i_item_sk = cr.wr_item_sk
    WHERE item.i_rec_start_date <= CURRENT_DATE AND (item.i_rec_end_date IS NULL OR item.i_rec_end_date > CURRENT_DATE)
    GROUP BY item.i_item_sk
),
FinalReport AS (
    SELECT
        ts.i_item_sk,
        ts.total_quantity_sold,
        ts.total_sales_amount,
        ts.total_returned,
        (ts.total_sales_amount - SUM(DISTINCT CASE WHEN ts.total_returned > 0 THEN ts.total_returned ELSE 0 END)) AS net_sales,
        CASE 
            WHEN ts.total_quantity_sold > 100 THEN 'High Volume'
            WHEN ts.total_quantity_sold BETWEEN 50 AND 100 THEN 'Medium Volume'
            WHEN ts.total_quantity_sold < 50 THEN 'Low Volume'
            ELSE 'Not Rated'
        END AS sales_category
    FROM TotalSales ts
    GROUP BY ts.i_item_sk, ts.total_quantity_sold, ts.total_sales_amount, ts.total_returned
)
SELECT
    fr.i_item_sk,
    fr.total_quantity_sold,
    fr.total_sales_amount,
    fr.total_returned,
    fr.net_sales,
    fr.sales_category
FROM FinalReport fr
WHERE fr.net_sales > 0
ORDER BY fr.net_sales DESC
LIMIT 100;
