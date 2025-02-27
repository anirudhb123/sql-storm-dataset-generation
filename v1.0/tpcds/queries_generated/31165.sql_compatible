
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_wholesale_cost, 1 AS level
    FROM item
    WHERE i_rec_start_date <= DATE '2002-10-01' AND i_rec_end_date >= DATE '2002-10-01'
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, CONCAT(ih.i_item_desc, ' > ', i.i_item_desc) AS i_item_desc, 
           i.i_current_price, i.i_wholesale_cost, ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON i.i_manager_id = ih.i_item_sk
    WHERE ih.level < 5
),
customer_sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_net_paid) AS total_spent, COUNT(ws.ws_order_number) AS orders_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) - 1 FROM date_dim))
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim))
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cs.total_spent,
           DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.orders_count > 5
),
item_sales AS (
    SELECT i.i_item_sk, SUM(ws.ws_quantity) AS total_quantity_sold, 
           SUM(ws.ws_net_paid) AS total_net_paid
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk
),
address_info AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, 
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT tc.c_first_name, tc.c_last_name, tc.total_spent, 
       ih.i_item_id, ih.i_item_desc, ih.i_current_price, 
       a.ca_city, a.ca_state, a.customer_count
FROM top_customers tc
JOIN item_hierarchy ih ON ih.i_item_sk IN (SELECT is_.i_item_sk FROM item_sales is_ 
                                            WHERE is_.total_quantity_sold > 100)
JOIN address_info a ON a.customer_count > 10
WHERE tc.sales_rank <= 10
ORDER BY tc.total_spent DESC, a.ca_city, a.ca_state;
