
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name,
           ch.c_current_cdemo_sk, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_customer_sk
    WHERE ch.level < 5
),
sales_summary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid) AS total_sales,
           COUNT(ws_order_number) AS order_count,
           AVG(ws_net_paid) AS avg_order_value
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
shipped_items AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 100
),
promoted_items AS (
    SELECT p.p_promo_id, p.p_promo_name, SUM(ws.ws_net_paid) AS promo_sales
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id, p.p_promo_name
),
item_overview AS (
    SELECT i.i_item_id, 
           i.i_item_desc, 
           COALESCE(s.total_quantity, 0) AS total_shipped,
           COALESCE(p.promo_sales, 0) AS total_promo_sales
    FROM item i
    LEFT JOIN shipped_items s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN promoted_items p ON i.i_item_sk = p.p_promo_sk
)
SELECT dh.d_date AS report_date,
       SUM(ss.total_sales) AS total_sales,
       AVG(ss.avg_order_value) AS average_order_value,
       COUNT(DISTINCT ch.c_customer_sk) AS total_unique_customers,
       COUNT(DISTINCT io.i_item_id) AS items_sold,
       SUM(CASE WHEN io.total_shipped > 0 THEN io.total_shipped ELSE NULL END) AS shipped_items_count
FROM date_dim dh
LEFT JOIN sales_summary ss ON dh.d_date_sk = ss.ws_bill_customer_sk
LEFT JOIN customer_hierarchy ch ON ch.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN item_overview io ON io.total_shipped > 0
WHERE dh.d_year = 2023
GROUP BY dh.d_date
ORDER BY report_date DESC
LIMIT 100;
