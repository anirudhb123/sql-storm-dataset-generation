
WITH RECURSIVE customer_tree AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag,
           ROW_NUMBER() OVER (PARTITION BY c_preferred_cust_flag ORDER BY c_customer_sk) as rank
    FROM customer
    WHERE c_birth_year IS NOT NULL
), sales_summary AS (
    SELECT 
        COALESCE(CONCAT(c.c_first_name, ' ', c.c_last_name), 'Unknown') AS full_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 
          (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND 
          (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY full_name
), item_analysis AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        AVG(ws.ws_sales_price) AS avg_sale_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(CASE WHEN ws.ws_net_profit < 0 THEN 1 ELSE 0 END) AS refund_count
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
)
SELECT s.full_name, 
       s.total_sales, 
       s.order_count, 
       it.i_item_id, 
       it.i_item_desc, 
       it.avg_sale_price, 
       it.order_count AS item_order_count, 
       it.refund_count
FROM sales_summary s
FULL OUTER JOIN item_analysis it ON s.order_count = it.order_count
WHERE (s.total_sales IS NOT NULL OR it.avg_sale_price IS NOT NULL)
  AND ((s.total_sales > 1000 AND it.avg_sale_price < 50) 
       OR (it.refund_count > 10 AND s.order_count < 5))
ORDER BY s.total_sales DESC NULLS LAST, it.avg_sale_price ASC NULLS FIRST
LIMIT 100
UNION ALL
SELECT 'Aggregate' AS full_name, 
       SUM(total_sales) AS total_sales, 
       COUNT(order_count) AS order_count, 
       NULL AS i_item_id, 
       NULL AS i_item_desc, 
       NULL AS avg_sale_price, 
       NULL AS item_order_count, 
       SUM(refund_count) AS refund_count
FROM (
    SELECT total_sales, order_count, 0 AS refund_count FROM sales_summary 
    UNION ALL 
    SELECT NULL, NULL, refund_count FROM item_analysis
) AS combined
HAVING SUM(total_sales) IS NOT NULL OR SUM(refund_count) IS NOT NULL;
