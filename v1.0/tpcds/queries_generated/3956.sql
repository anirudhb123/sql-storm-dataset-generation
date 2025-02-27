
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
item_sales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS average_price
    FROM item AS i
    JOIN web_sales AS ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
),
top_items AS (
    SELECT 
        i.i_item_id,
        total_sold,
        average_price,
        RANK() OVER (ORDER BY total_sold DESC) AS item_rank
    FROM item_sales AS is
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_profit,
    cs.order_count,
    ti.i_item_id,
    ti.total_sold,
    ti.average_price
FROM customer_sales AS cs
JOIN top_items AS ti ON cs.c_customer_sk IN (
    SELECT DISTINCT ws.ws_bill_customer_sk
    FROM web_sales AS ws
    WHERE ws.ws_item_sk IN (
        SELECT i.i_item_sk
        FROM item AS i
        WHERE i.i_item_id IN (SELECT i_item_id FROM top_items WHERE item_rank <= 10)
    )
)
WHERE cs.total_profit IS NOT NULL AND cs.order_count > 0
ORDER BY cs.total_profit DESC, ti.total_sold DESC;
