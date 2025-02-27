
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 0 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_profit
    FROM web_sales ws
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_net_profit), 0) AS net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    cs.net_profit,
    cs.order_count,
    (
        SELECT COUNT(*) 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = ch.c_customer_sk
    ) AS store_order_count,
    (
        SELECT SUM(inv.inv_quantity_on_hand) 
        FROM inventory inv 
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        WHERE i.i_item_sk IN (SELECT ws_item_sk FROM ranked_sales WHERE sales_rank <= 5)
    ) AS total_inventory
FROM customer_hierarchy ch 
JOIN customer_sales cs ON ch.c_customer_sk = cs.c_customer_sk
WHERE cs.net_profit > 1000 OR ch.level = 0
ORDER BY cs.net_profit DESC, ch.c_last_name, ch.c_first_name;
