
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name
    FROM item
    WHERE i_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0)

    UNION ALL

    SELECT ch.i_item_sk, ch.i_item_id, ch.i_product_name
    FROM item_hierarchy ih
    JOIN item ch ON ih.i_item_sk = ch.i_item_sk
    WHERE ch.i_item_id LIKE '%A%'
), 
negative_returns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_negative_returns
    FROM store_returns
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_quantity) < 0
),
web_sales_summary AS (
    SELECT ws_item_sk, SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
joined_data AS (
    SELECT 
        ih.i_item_sk,
        ih.i_product_name,
        COALESCE(nr.total_negative_returns, 0) AS negative_returns,
        COALESCE(ws.total_profit, 0) AS total_profit
    FROM item_hierarchy ih
    LEFT JOIN negative_returns nr ON ih.i_item_sk = nr.sr_item_sk
    LEFT JOIN web_sales_summary ws ON ih.i_item_sk = ws.ws_item_sk
)
SELECT 
    j.i_item_sk,
    j.i_product_name,
    j.negative_returns,
    j.total_profit,
    CASE 
        WHEN j.total_profit = 0 THEN 'No Profit'
        WHEN j.negative_returns > 0 THEN 'High Return Rate'
        ELSE 'Profit Margin Active'
    END AS return_status
FROM joined_data j
WHERE j.negative_returns IS NOT NULL
    AND j.total_profit IS NOT NULL
ORDER BY j.total_profit DESC, j.negative_returns ASC
FETCH FIRST 10 ROWS ONLY;
