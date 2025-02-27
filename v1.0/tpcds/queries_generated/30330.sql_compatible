
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit
    FROM catalog_sales
    GROUP BY cs_sold_date_sk, cs_item_sk
),
final_sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_net_profit,
        COALESCE(c.ca_state, 'UNKNOWN') AS state
    FROM sales_data s
    LEFT JOIN item i ON s.ws_item_sk = i.i_item_sk
    LEFT JOIN customer c ON i.i_item_sk = c.c_current_addr_sk
)
SELECT 
    fs.ws_item_sk,
    fs.total_quantity,
    fs.total_net_profit,
    fs.state,
    ROW_NUMBER() OVER(PARTITION BY fs.state ORDER BY fs.total_net_profit DESC) AS rank,
    CASE 
        WHEN fs.total_net_profit IS NULL THEN 'No Profit'
        WHEN fs.total_net_profit > 1000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM final_sales fs
WHERE fs.state IS NOT NULL
AND fs.total_quantity > (
    SELECT AVG(total_quantity) 
    FROM final_sales 
    WHERE state IS NOT NULL
)
ORDER BY fs.total_net_profit DESC
LIMIT 50;
