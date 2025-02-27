
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_city, ca.ca_state, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ah.ca_city = ca.ca_city AND ah.level < 5
),
income_bracket as (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
),
customer_sales_data AS (
    SELECT c.c_customer_sk, 
           c.c_first_name || ' ' || c.c_last_name AS full_name,
           d.d_date,
           SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales,
           COUNT(DISTINCT cs.cs_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date
),
top_customers AS (
    SELECT c.*, ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM customer_sales_data c
    WHERE rank = 1
)
SELECT a.ca_city, a.ca_state, 
       COALESCE(tc.total_sales, 0) AS customer_sales,
       ib.ib_income_band_sk AS income_band,
       COUNT(DISTINCT c.c_customer_id) AS customer_count,
       MAX(tc.total_sales) AS max_sales_per_customer,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders,
       SUM(CASE WHEN tc.total_sales >= 1000 THEN 1 ELSE 0 END) AS high_value_customers
FROM address_hierarchy a
LEFT JOIN top_customers tc ON tc.c_customer_sk IN (
    SELECT DISTINCT c.c_customer_sk 
    FROM customer c 
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'S'
)
LEFT JOIN customer c ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN income_bracket ib ON cb.lbl_income_band_sk = tc.order_count % 10
GROUP BY a.ca_city, a.ca_state, ib.ib_income_band_sk
HAVING MAX(tc.total_sales) > (SELECT AVG(total_sales) FROM top_customers)
ORDER BY customer_sales DESC NULLS LAST;
