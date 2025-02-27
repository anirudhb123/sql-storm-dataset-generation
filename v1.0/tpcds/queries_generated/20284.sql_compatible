
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_customer_id, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_net_paid
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        ir.total_quantity,
        ir.total_net_paid,
        DENSE_RANK() OVER (ORDER BY ir.total_quantity DESC) AS quantity_rank
    FROM item_sales ir
)
SELECT 
    ch.c_customer_id,
    ch.level AS customer_level,
    ti.i_item_id,
    ti.total_quantity,
    ti.total_net_paid
FROM customer_hierarchy ch
JOIN (
    SELECT 
        ti.i_item_id,
        ti.total_quantity,
        ti.total_net_paid
    FROM top_items ti
    WHERE ti.quantity_rank <= 10
) ti ON ti.total_quantity IS NOT NULL
ORDER BY ch.c_customer_id, ti.total_quantity DESC;
