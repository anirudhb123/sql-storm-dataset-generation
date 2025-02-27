
WITH RECURSIVE income_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_ranges ir ON ir.ib_upper_bound = ib.ib_lower_bound
),
sales_data AS (
    SELECT ws.web_site_id, 
           SUM(ws.ws_net_paid_inc_tax) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           AVG(ws.ws_net_paid_inc_tax) AS average_order_value
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk 
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_id
),
customer_stats AS (
    SELECT c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           COUNT(ws.ws_order_number) AS order_count,
           SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
address_summary AS (
    SELECT ca.ca_state,
           COUNT(DISTINCT c.c_customer_id) AS unique_customers,
           SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ca.ca_state
),
combined_summary AS (
    SELECT cu.c_customer_id, 
           cu.order_count, 
           cu.total_spent,
           ad.unique_customers,
           ad.total_sales AS state_sales,
           sa.total_sales AS website_sales
    FROM customer_stats cu
    JOIN address_summary ad ON ad.unique_customers > 0
    JOIN sales_data sa ON sa.total_orders > 0
),
final_summary AS (
    SELECT *, 
           CASE 
               WHEN total_spent > 1000 THEN 'High Value'
               WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS value_segment
    FROM combined_summary
)
SELECT *,
       RANK() OVER (PARTITION BY value_segment ORDER BY total_spent DESC) AS rank_within_segment,
       COUNT(*) OVER (PARTITION BY value_segment) AS total_in_segment
FROM final_summary
WHERE unique_customers IS NOT NULL AND total_spent IS NOT NULL
ORDER BY value_segment, rank_within_segment;
