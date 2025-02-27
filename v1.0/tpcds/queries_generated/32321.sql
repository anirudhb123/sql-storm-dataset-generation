
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           0 AS hierarchy_level, CAST(c.c_first_name || ' ' || c.c_last_name AS VARCHAR(100)) AS full_name
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_current_cdemo_sk,
           ch.hierarchy_level + 1, CAST(CAST(ch.full_name AS VARCHAR(100)) || ' -> ' || c.c_first_name || ' ' || c.c_last_name AS VARCHAR(100))
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE ch.hierarchy_level < 5  -- Limit depth of recursion
),
sales_summary AS (
    SELECT ws.ws_bill_customer_sk, 
           SUM(ws.ws_net_paid_inc_tax) AS total_sales,
           COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 3) 
    GROUP BY ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT ch.full_name, cs.total_sales, cs.total_orders
    FROM customer_hierarchy ch
    JOIN sales_summary cs ON ch.c_customer_sk = cs.ws_bill_customer_sk
    ORDER BY cs.total_sales DESC
    LIMIT 10
)
SELECT tc.full_name, 
       COALESCE(tc.total_sales, 0) AS total_sales,
       COALESCE(tc.total_orders, 0) AS total_orders,
       CASE 
           WHEN tc.total_sales IS NULL THEN 'No Sales'
           WHEN tc.total_sales > 1000 THEN 'High Value'
           WHEN tc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value,
       s.s_store_name,
       w.w_warehouse_name,
       ROW_NUMBER() OVER (PARTITION BY tc.customer_value ORDER BY tc.total_sales DESC) AS rank_within_value
FROM top_customers tc
LEFT JOIN store s ON s.s_store_sk = (SELECT ss.ss_store_sk FROM store_sales ss WHERE ss.ss_customer_sk = tc.ws_bill_customer_sk LIMIT 1)
LEFT JOIN warehouse w ON w.w_warehouse_sk = (SELECT ws.ws_warehouse_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.ws_bill_customer_sk LIMIT 1);
