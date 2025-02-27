
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 'No Price'
            ELSE 'Has Price'
        END AS price_status
    FROM web_sales ws
    WHERE ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) 
                                FROM web_sales ws2 
                                WHERE ws2.ws_item_sk = ws.ws_item_sk)
),
inventory_summary AS (
    SELECT 
        i.inv_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
        CASE 
            WHEN SUM(i.inv_quantity_on_hand) < 50 THEN 'Low Stock'
            WHEN SUM(i.inv_quantity_on_hand) BETWEEN 50 AND 200 THEN 'Medium Stock'
            ELSE 'High Stock'
        END AS stock_status
    FROM inventory i
    GROUP BY i.inv_item_sk
),
return_summary AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        CASE 
            WHEN SUM(sr.sr_return_amt) IS NULL THEN 0
            ELSE SUM(sr.sr_return_amt)
        END AS adjusted_return_amount
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
)
SELECT 
    i.inv_item_sk,
    COALESCE(rs.price_rank, 'No Sales') AS highest_price_rank,
    COALESCE(is.total_quantity_on_hand, 0) AS quantity_on_hand,
    COALESCE(rs.price_status, 'No Sales') AS sales_status,
    COALESCE(rs.ws_sales_price, 0) AS last_sales_price,
    COALESCE(rs.price_rank, 0) + COALESCE(rs.total_returns, 0) AS combined_metric,
    CONCAT_WS(' - ', ISNULL(is.stock_status, 'No Stock'), ISNULL(rs.price_status, 'No Sales')) AS stock_sales_combined
FROM inventory_summary is
FULL OUTER JOIN ranked_sales rs ON is.inv_item_sk = rs.ws_item_sk
LEFT JOIN return_summary r ON rs.ws_item_sk = r.sr_item_sk
WHERE (is.total_quantity_on_hand > 0 OR rs.price_rank IS NOT NULL)
ORDER BY combined_metric DESC;
