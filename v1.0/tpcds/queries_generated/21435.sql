
WITH ranked_sales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rnk
    FROM web_sales
    WHERE ws_quantity > 0
),
seasonal_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM store_returns
    WHERE sr_returned_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_month_seq IN (SELECT d_month_seq FROM date_dim WHERE d_year = 2023 AND d_dow IN (6, 7))
    )
    GROUP BY sr_item_sk
),
income_distribution AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(c.c_customer_id) AS customer_count
    FROM household_demographics h
    JOIN customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    WHERE h.hd_buy_potential = 'High'
    GROUP BY h.hd_income_band_sk
),
lowest_sales AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk
    HAVING SUM(inv_quantity_on_hand) < 10
)
SELECT 
    ws.ws_item_sk,
    SUM(ws.ws_quantity) AS total_sold,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(rr.total_returned, 0) AS total_returns,
    COALESCE(rr.unique_returns, 0) AS total_unique_returns,
    CASE 
        WHEN SUM(ws.ws_quantity) > 100 THEN 'High Volume'
        WHEN SUM(ws.ws_quantity) BETWEEN 50 AND 100 THEN 'Moderate Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
FROM web_sales ws
LEFT JOIN seasonal_returns rr ON ws.ws_item_sk = rr.sr_item_sk
JOIN ranked_sales rs ON ws.ws_item_sk = rs.ws_item_sk AND rs.rnk = 1
LEFT JOIN lowest_sales ls ON ws.ws_item_sk = ls.inv_item_sk
WHERE ws.ws_ship_date_sk > 0
GROUP BY ws.ws_item_sk
HAVING SUM(ws.ws_net_profit) IS NOT NULL AND SUM(ws.ws_quantity) IS NOT NULL
ORDER BY sales_rank
LIMIT 100
