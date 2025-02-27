
WITH RECURSIVE sales_summary AS (
    SELECT ss.sold_date_sk, ss.s_item_sk, SUM(ss.ss_quantity) AS total_quantity, SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ss.sold_date_sk, ss.s_item_sk
    UNION ALL
    SELECT ss.sold_date_sk, ss.s_item_sk, SUM(ss.ss_quantity), SUM(ss.ss_net_paid)
    FROM store_sales ss
    INNER JOIN sales_summary s ON ss.s_item_sk = s.s_item_sk
    WHERE ss.sold_date_sk < s.sold_date_sk
    GROUP BY ss.sold_date_sk, ss.s_item_sk
),
customer_sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_net_paid) AS total_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cs.total_spent,
           RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
item_sales AS (
    SELECT i.i_item_sk, i.i_item_id, SUM(ws.ws_quantity) AS total_quantity_sold,
           AVG(ws.ws_ext_sales_price) AS avg_sales_price
    FROM web_sales ws
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
)
SELECT t.c_first_name, t.c_last_name, t.total_spent, i.i_item_id,
       ISNULL(s.total_quantity, 0) AS total_quantity_sold, 
       COALESCE(i.avg_sales_price, 0) AS avg_sales_price,
       CASE 
           WHEN t.customer_rank <= 5 THEN 'Top Customer'
           ELSE 'Regular Customer'
       END AS customer_category
FROM top_customers t
LEFT JOIN item_sales i ON t.c_customer_sk = i.i_item_sk
LEFT JOIN sales_summary s ON i.i_item_sk = s.s_item_sk
WHERE t.total_spent > (
    SELECT AVG(total_spent)
    FROM top_customers
)
ORDER BY t.total_spent DESC;
