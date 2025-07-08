
WITH RECURSIVE sales_cte AS (
    SELECT ws_sold_date_sk, 
           ws_item_sk, 
           ws_quantity, 
           ws_net_paid, 
           1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)

    UNION ALL

    SELECT ws.ws_sold_date_sk, 
           ws.ws_item_sk, 
           ws.ws_quantity, 
           ws.ws_net_paid, 
           cte.level + 1
    FROM web_sales ws
    JOIN sales_cte cte ON ws.ws_sold_date_sk = cte.ws_sold_date_sk - cte.level
    WHERE cte.level < 5
),
customer_stats AS (
    SELECT c.c_customer_sk, 
           SUM(ws.ws_net_paid) AS total_spent,
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased,
           DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT cs.c_customer_sk, 
           cs.total_spent, 
           cs.order_count, 
           cs.unique_items_purchased
    FROM customer_stats cs
    WHERE cs.rank <= 10
),
inventory_status AS (
    SELECT i.inv_item_sk, 
           SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM inventory i
    GROUP BY i.inv_item_sk
),
top_item AS (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_bill_customer_sk IN (SELECT c_customer_sk FROM top_customers)
    ORDER BY ws_net_paid DESC
    LIMIT 1
)
SELECT t.c_customer_sk, 
       t.total_spent, 
       t.order_count, 
       t.unique_items_purchased, 
       inv.total_inventory,
       (SELECT COUNT(*) FROM store s WHERE s.s_state = 'CA') AS ca_stores_count
FROM top_customers t
LEFT JOIN inventory_status inv ON inv.inv_item_sk = (SELECT ws_item_sk FROM top_item)
WHERE t.order_count > 5
ORDER BY t.total_spent DESC;
