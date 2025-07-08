
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_desc, i_current_price, i_rec_start_date, i_rec_end_date, i_item_id, 1 AS level
    FROM item
    WHERE i_rec_end_date > DATE '2002-10-01'
    UNION ALL
    SELECT i.i_item_sk, i.i_item_desc, i.i_current_price * 0.9 AS i_current_price, i.i_rec_start_date, i.i_rec_end_date, i.i_item_id, ih.level + 1
    FROM item i
    JOIN item_hierarchy ih ON i.i_item_sk = ih.i_item_sk
    WHERE ih.level < 5
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ws.ws_net_paid) AS total_spent,
    AVG(ws.ws_net_paid) AS avg_spent,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    CASE
        WHEN SUM(ws.ws_net_paid) > 1000 THEN 'High Value'
        WHEN SUM(ws.ws_net_paid) BETWEEN 500 AND 1000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS row_num
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN item_hierarchy ih ON ws.ws_item_sk = ih.i_item_sk
WHERE ws.ws_sold_date_sk IN (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001 AND d_month_seq IN (1, 2, 3)
)
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city
HAVING COUNT(DISTINCT ws.ws_order_number) > 1
ORDER BY total_spent DESC
FETCH FIRST 10 ROWS ONLY;
