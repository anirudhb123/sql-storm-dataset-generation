
WITH RECURSIVE sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) IS NOT NULL
    UNION ALL
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM catalog_sales
    GROUP BY cs_item_sk
    HAVING SUM(cs_quantity) IS NOT NULL
),
ranked_sales AS (
    SELECT
        sd.ws_item_sk,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_profit, 0) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_profit DESC) AS row_rank
    FROM (
        SELECT ws_item_sk, total_quantity, total_profit FROM sales_data
        WHERE rank = 1
    ) AS sd
    LEFT JOIN (
        SELECT cs_item_sk, SUM(cs_quantity) AS total_quantity, SUM(cs_net_profit) AS total_profit
        FROM catalog_sales
        GROUP BY cs_item_sk
    ) AS cs ON sd.ws_item_sk = cs.cs_item_sk
),
store_info AS (
    SELECT
        s_store_sk,
        s_store_name,
        s.city,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_store_profit
    FROM store s
    JOIN web_sales ws ON ws.ws_ship_addr_sk = s.s_store_sk
    GROUP BY s_store_sk, s_store_name, s.city
)
SELECT
    rs.ws_item_sk,
    rs.total_quantity,
    rs.total_profit,
    si.s_store_name,
    si.total_orders,
    si.total_store_profit,
    CASE
        WHEN rs.total_profit = 0 THEN 'No Profit'
        ELSE CONCAT('Profitable:', ROUND((rs.total_profit / NULLIF(si.total_store_profit, 0)) * 100, 2), '%')
    END AS profit_percentage,
    PERCENT_RANK() OVER (ORDER BY rs.total_profit DESC) AS profit_rank
FROM ranked_sales rs
FULL OUTER JOIN store_info si ON rs.ws_item_sk = si.s_store_sk
WHERE si.total_orders > (SELECT AVG(total_orders) FROM store_info) OR si.total_store_profit IS NULL
ORDER BY rs.total_profit DESC NULLS LAST;
