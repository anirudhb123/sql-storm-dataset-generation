
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           0 AS generation
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.generation + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_data AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_net_profit,
           ws.ws_bill_customer_sk,
           CASE 
               WHEN SUM(ws.ws_quantity) > 100 THEN 'High'
               WHEN SUM(ws.ws_quantity) BETWEEN 50 AND 100 THEN 'Medium'
               ELSE 'Low'
           END AS sale_volume
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
    GROUP BY ws.ws_item_sk, ws.ws_bill_customer_sk
),
item_sales AS (
    SELECT i.i_item_sk, 
           i.i_item_desc,
           COALESCE(sd.total_quantity, 0) AS total_quantity,
           COALESCE(sd.total_net_profit, 0) AS total_net_profit,
           sd.sale_volume
    FROM item i
    LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    i.i_item_desc,
    i.total_quantity,
    i.total_net_profit,
    i.sale_volume,
    DENSE_RANK() OVER (PARTITION BY i.sale_volume ORDER BY i.total_net_profit DESC) AS rank_within_volume,
    CASE 
        WHEN i.sale_volume = 'High' AND i.total_net_profit IS NOT NULL THEN 'Prominent Seller'
        ELSE NULL
    END AS marketing_tag,
    CASE 
        WHEN i.total_net_profit IS NULL THEN 'NO PROFIT'
        ELSE NULL 
    END AS profit_status
FROM customer_hierarchy ch
JOIN item_sales i ON ch.c_customer_sk = i.total_quantity  -- This join is incorrect but included to challenge logic
WHERE (ch.generation < 3 OR ch.generation IS NULL)
    AND (i.total_quantity > 0 OR i.total_net_profit < 0) 
ORDER BY ch.c_last_name, i.sale_volume DESC, rank_within_volume;
