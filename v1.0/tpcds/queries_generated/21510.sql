
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn,
        COALESCE(SUM(ws.ws_ext_tax) OVER (PARTITION BY ws.ws_order_number), 0) AS total_tax,
        COUNT(DISTINCT ws.ws_ship_mode_sk) OVER (PARTITION BY ws.ws_order_number) AS mode_count
    FROM web_sales ws
    WHERE ws.ws_sales_price > 0
), SalesAggregate AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        AVG(rs.ws_sales_price) AS avg_sales_price,
        COUNT(*) AS item_count,
        MAX(rs.total_tax) AS max_tax,
        MIN(CASE WHEN rs.rn = 1 THEN rs.ws_sales_price ELSE NULL END) AS min_top_price,
        MAX(CASE WHEN rs.rn = 1 THEN rs.ws_sales_price ELSE NULL END) AS max_top_price
    FROM RankedSales rs
    GROUP BY rs.ws_order_number
), ReturnDetails AS (
    SELECT 
        wr.wr_order_number,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_value
    FROM web_returns wr
    GROUP BY wr.wr_order_number
), FinalReport AS (
    SELECT 
        sa.ws_order_number,
        sa.total_sales,
        sa.avg_sales_price,
        rd.total_returned,
        rd.total_return_value,
        sa.item_count,
        sa.max_tax,
        sa.min_top_price,
        sa.max_top_price,
        CASE 
            WHEN rd.total_returned IS NULL THEN 'No Returns'
            WHEN rd.total_returned > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM SalesAggregate sa
    LEFT JOIN ReturnDetails rd ON sa.ws_order_number = rd.wr_order_number
)
SELECT
    fw.ws_order_number,
    fw.total_sales,
    fw.avg_sales_price,
    fw.total_returned,
    fw.total_return_value,
    (fw.total_sales - COALESCE(fw.total_return_value, 0)) AS net_sales,
    fw.return_status
FROM FinalReport fw
WHERE
    fw.total_sales > 1000 
    AND (fw.avg_sales_price / NULLIF(fw.item_count, 0)) < 200
ORDER BY net_sales DESC
FETCH FIRST 10 ROWS ONLY;
