
WITH RecursiveItemReturns AS (
    SELECT wr_item_sk,
           wr_return_quantity,
           ROW_NUMBER() OVER (PARTITION BY wr_item_sk ORDER BY wr_returned_date_sk) AS rnk
    FROM web_returns
    WHERE wr_return_quantity IS NOT NULL
),
ItemStats AS (
    SELECT i.i_item_id,
           i.i_product_name,
           COALESCE(NULLIF(SUM(CASE WHEN ws_quantity IS NOT NULL THEN ws_quantity ELSE 0 END), 0), 1) AS total_sales,
           COALESCE(NULLIF(SUM(CASE WHEN sr_return_quantity IS NOT NULL THEN sr_return_quantity ELSE 0 END), 0), 1) AS total_returns,
           SUM(CASE WHEN sr_return_quantity IS NOT NULL THEN sr_return_quantity ELSE 0 END) AS total_returned,
           (SELECT COUNT(DISTINCT ws_order_number) FROM web_sales WHERE ws_item_sk = i.i_item_sk) AS total_orders
    FROM item i
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_product_name
),
SalesAnalysis AS (
    SELECT *,
           CASE WHEN total_returns > total_sales THEN 'High Return'
                WHEN total_returns = 0 THEN 'No Return'
                ELSE 'Normal Return' END AS return_status,
           total_returns::decimal / NULLIF(total_sales, 0) AS return_ratio,
           RANK() OVER (ORDER BY return_ratio DESC) AS return_rank
    FROM ItemStats
)
SELECT s.s_store_name,
       a.i_item_id,
       a.i_product_name,
       a.total_sales,
       a.total_returns,
       a.return_status,
       a.return_ratio,
       RANK() OVER (PARTITION BY s.s_store_sk ORDER BY a.return_ratio DESC) AS store_return_rank
FROM SalesAnalysis a
JOIN store s ON s.s_store_sk = a.total_orders % (SELECT COUNT(*) FROM store) + 1
WHERE a.return_status = 'High Return'
  AND s.s_state IS NOT NULL
ORDER BY s.s_store_name, a.return_rank
LIMIT 10;
