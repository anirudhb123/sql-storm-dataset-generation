
WITH RECURSIVE DateSeries AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_date BETWEEN '2022-01-01' AND '2022-12-31'
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, d.d_month_seq
    FROM date_dim d
    JOIN DateSeries ds ON d.d_date_sk = ds.d_date_sk + 1
),
RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_quantity DESC) AS rank_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM DateSeries)
    AND ws.ws_sales_price IS NOT NULL
),
TopSales AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM RankedSales
    WHERE rank_sales <= 3
    GROUP BY ws_order_number, ws_item_sk
),
CustomerReturns AS (
    SELECT
        wr_refunded_customer_sk AS customer_id,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_value
    FROM web_returns
    WHERE wr_returned_date_sk IN (SELECT d_date_sk FROM DateSeries)
    GROUP BY wr_refunded_customer_sk
),
FinalReport AS (
    SELECT
        cs.customer_id,
        COALESCE(ts.total_quantity, 0) AS total_quantity_sold,
        COALESCE(ts.total_sales, 0) AS total_sales_value,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value
    FROM (SELECT DISTINCT wr_refunded_customer_sk AS customer_id FROM web_returns) cs
    LEFT JOIN TopSales ts ON cs.customer_id = ts.ws_order_number
    LEFT JOIN CustomerReturns cr ON cs.customer_id = cr.customer_id
)
SELECT 
    f.customer_id,
    f.total_quantity_sold,
    f.total_sales_value,
    f.total_returns,
    f.total_return_value,
    CASE 
        WHEN f.total_sales_value = 0 THEN 'No Sales'
        WHEN f.total_returns > f.total_quantity_sold THEN 'Excessive Returns'
        ELSE 'Normal Activity'
    END AS performance_status
FROM FinalReport f
WHERE f.total_sales_value IS NOT NULL 
  AND f.total_returns IS NOT NULL
ORDER BY f.total_sales_value DESC
LIMIT 100;
