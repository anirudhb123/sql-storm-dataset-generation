
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           ROW_NUMBER() OVER (ORDER BY c_customer_sk) AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.current_cdemo_sk = ch.c_current_cdemo_sk
), price_summary AS (
    SELECT i.i_item_id, 
           SUM(ws.ws_ext_sales_price) AS total_sales,
           SUM(ws.ws_ext_discount_amt) AS total_discount,
           COUNT(ws.ws_order_number) AS total_orders
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
), demographic_summary AS (
    SELECT cd.cd_gender,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)

SELECT ch.c_first_name, ch.c_last_name,
       ps.total_sales, ps.total_discount, ps.total_orders,
       ds.avg_purchase_estimate, ds.customer_count
FROM customer_hierarchy ch
LEFT JOIN price_summary ps ON ch.c_customer_sk = ps.i_item_id
FULL OUTER JOIN demographic_summary ds ON ch.c_current_cdemo_sk = ds.customer_count
WHERE (ch.level > 1 OR ds.avg_purchase_estimate > 1000)
AND (ps.total_sales IS NOT NULL OR ds.customer_count IS NULL)
ORDER BY ch.c_first_name, ch.c_last_name;
