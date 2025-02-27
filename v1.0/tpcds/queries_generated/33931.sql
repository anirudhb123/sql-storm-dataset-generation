
WITH RECURSIVE sales_history AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rnk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
                                 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_performance AS (
    SELECT c.c_customer_id, 
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           SUM(CASE WHEN c.c_birth_month = d.d_month THEN ws_ext_sales_price ELSE 0 END) AS current_month_sales
    FROM customer c
    JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    JOIN date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_id
),
high_value_customers AS (
    SELECT c.c_customer_id, total_sales, order_count, current_month_sales,
           CASE 
               WHEN total_sales > 1000 THEN 'High Value'
               WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS customer_value
    FROM customer_performance c
    WHERE current_month_sales > 0
)
SELECT hvc.customer_value,
       COUNT(hvc.c_customer_id) AS customer_count,
       AVG(hvc.total_sales) AS avg_sales,
       MAX(hvc.current_month_sales) AS max_sales
FROM high_value_customers hvc
LEFT JOIN customer_address ca ON hvc.c_customer_id = ca.ca_address_id
WHERE ca.ca_state IN ('CA', 'TX') 
  AND hvc.customer_value = 'High Value'
GROUP BY hvc.customer_value
ORDER BY customer_count DESC;

