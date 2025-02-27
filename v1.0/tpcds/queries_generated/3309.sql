
WITH recent_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year,
           DENSE_RANK() OVER (PARTITION BY c_birth_month ORDER BY c_birth_day DESC) AS birth_rank
    FROM customer
    WHERE c_birth_year >= 1990
),
sales_summary AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_net_paid) AS total_spent,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023
    )
    GROUP BY ws_bill_customer_sk
),
premium_customers AS (
    SELECT r.c_customer_sk,
           CONCAT(r.c_first_name, ' ', r.c_last_name) AS full_name,
           r.c_birth_year,
           s.total_spent,
           COALESCE(s.order_count, 0) AS order_count,
           CASE 
               WHEN s.total_spent > 1000 THEN 'Premium'
               ELSE 'Standard'
           END AS customer_status
    FROM recent_customers r
    LEFT JOIN sales_summary s ON r.c_customer_sk = s.customer_sk
)
SELECT pc.full_name,
       pc.customer_status,
       pc.total_spent,
       COALESCE(pc.order_count, 0) AS number_of_orders,
       CASE
           WHEN pc.order_count IS NULL THEN 'No Orders'
           WHEN pc.order_count < 5 THEN 'Few Orders'
           ELSE 'Regular Customer'
       END AS order_behavior
FROM premium_customers pc
WHERE pc.birth_rank <= 3
ORDER BY pc.total_spent DESC, pc.full_name ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
