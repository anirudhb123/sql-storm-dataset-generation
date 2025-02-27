
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
), ranked_sales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_profit DESC) AS overall_rank
    FROM sales_data sd
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    r.total_quantity,
    r.total_profit,
    COALESCE(ROUND(r.total_profit / NULLIF(r.total_quantity, 0), 2), 0) AS avg_profit_per_unit,
    CASE 
        WHEN r.total_profit > 1000 THEN 'High Profit'
        WHEN r.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    ca.ca_city,
    ca.ca_state
FROM ranked_sales r
JOIN item i ON r.ws_item_sk = i.i_item_sk
LEFT JOIN customer_address ca ON ca.ca_address_sk = (
    SELECT c.c_current_addr_sk
    FROM customer c
    WHERE c.c_customer_sk IN (
        SELECT DISTINCT ws_ship_customer_sk
        FROM web_sales
        WHERE ws_item_sk = r.ws_item_sk
    )
    LIMIT 1
)
WHERE r.overall_rank <= 10
ORDER BY r.total_profit DESC;
