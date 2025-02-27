
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
top_customers AS (
    SELECT
        customer_id,
        total_profit,
        total_orders
    FROM sales_hierarchy
    WHERE rank <= 10
),
item_performance AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
),
best_selling_items AS (
    SELECT
        i.i_item_id,
        total_quantity_sold,
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_quantity_sold DESC) AS item_rank
    FROM item_performance i
    WHERE total_profit > 1000
)
SELECT 
    tc.customer_id,
    tc.total_profit AS customer_profit,
    tb.i_item_id,
    tb.total_quantity_sold,
    tb.total_profit AS item_profit
FROM top_customers tc
CROSS JOIN best_selling_items tb
WHERE tc.total_orders > 5
AND tb.item_rank <= 5
ORDER BY tc.customer_profit DESC, tb.total_quantity_sold DESC;
