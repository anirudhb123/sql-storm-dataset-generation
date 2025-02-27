
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) AS rank_quantity
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023) 
        AND ws_net_profit IS NOT NULL
),
summary AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(ranked_sales.ws_quantity), 0) AS total_quantity,
        SUM(ranked_sales.ws_net_profit) AS total_net_profit
    FROM
        item
    LEFT JOIN
        ranked_sales ON item.i_item_sk = ranked_sales.ws_item_sk AND ranked_sales.rank_profit <= 5
    GROUP BY
        item.i_item_id, item.i_item_desc
),
top_items AS (
    SELECT
        *,
        CASE 
            WHEN total_net_profit > 1000 THEN 'High Profit'
            WHEN total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_band
    FROM
        summary
)
SELECT
    ca.city,
    ca.state,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit,
    ti.profit_band
FROM
    top_items ti
INNER JOIN
    customer_address ca ON ca.ca_address_sk = (
        SELECT c_current_addr_sk 
        FROM customer 
        WHERE c_customer_sk = (
            SELECT ws_bill_customer_sk 
            FROM web_sales 
            WHERE ws_item_sk = ti.i_item_sk 
            ORDER BY ws_net_profit DESC 
            LIMIT 1
        )
    )
WHERE 
    ca.ca_state IS NOT NULL
    AND (ti.total_quantity > 0 OR ti.total_net_profit IS NOT NULL)
GROUP BY
    ca.city, ca.state, ti.i_item_id, ti.i_item_desc, ti.total_quantity, ti.total_net_profit, ti.profit_band
HAVING 
    COUNT(DISTINCT ca.ca_city) > 1
ORDER BY
    ti.total_net_profit DESC,
    ca.city
LIMIT 100
OFFSET 10;
