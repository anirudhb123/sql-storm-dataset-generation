
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE c.c_customer_sk != ch.c_customer_sk
),
customer_data AS (
    SELECT ca.city, ca.state, cd.cd_marital_status,
           COUNT(DISTINCT ch.c_customer_sk) AS customer_count,
           SUM(COALESCE(ws.net_paid, 0)) AS total_spent
    FROM customer_hierarchy ch
    JOIN customer_address ca ON ch.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ch.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ca.city IS NOT NULL
    GROUP BY ca.city, ca.state, cd.cd_marital_status
),
aggregated_data AS (
    SELECT city, state, cd_marital_status,
           -SUM(CASE WHEN customer_count IS NULL THEN 0 ELSE customer_count END) AS adjusted_count,
           SUM(total_spent) FILTER (WHERE total_spent > 100) AS high_spenders
    FROM customer_data
    GROUP BY city, state, cd_marital_status
),
row_ranks AS (
    SELECT city, state, cd_marital_status,
           adjusted_count,
           high_spenders,
           RANK() OVER (PARTITION BY state ORDER BY adjusted_count DESC) AS rank_by_count,
           RANK() OVER (PARTITION BY cd_marital_status ORDER BY high_spenders DESC) AS rank_by_spending
    FROM aggregated_data
)
SELECT city, state, cd_marital_status, adjusted_count, high_spenders, 
       CASE WHEN rank_by_count <= 5 THEN 'Top City by Count' ELSE 'Others' END AS city_count_category,
       CASE WHEN rank_by_spending <= 3 THEN 'Top Spender' ELSE 'Regular' END AS spending_category
FROM row_ranks
WHERE (adjusted_count > 0 OR high_spenders IS NOT NULL) 
  AND (cd_marital_status IN ('M', 'S') OR city IS NOT NULL)
ORDER BY state, adjusted_count DESC, high_spenders DESC;
