
WITH RECURSIVE customer_tree AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year, 
           COALESCE(cd_demo_sk, -1) AS demo_sk,
           0 AS level
    FROM customer
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE c_birth_year IS NOT NULL

    UNION ALL

    SELECT ct.c_customer_sk, ct.c_first_name, ct.c_last_name, ct.c_birth_year,
           COALESCE(cd_demo_sk, -1),
           level + 1
    FROM customer_tree ct
    JOIN customer demog ON ct.demo_sk = demog.c_current_cdemo_sk
    WHERE level < 5
),
address_summary AS (
    SELECT ca_state, COUNT(*) AS address_count,
           SUM( CASE WHEN ca_city IS NULL THEN 1 ELSE 0 END) AS null_city_count
    FROM customer_address
    GROUP BY ca_state
),
sales_summary AS (
    SELECT w.w_warehouse_name,
           SUM(ws_sales_price * ws_quantity) AS total_sales,
           SUM(ws_ext_tax) AS total_tax,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2023
    )
    GROUP BY w.w_warehouse_name
),
combined_info AS (
    SELECT ct.c_customer_sk, ct.c_first_name, ct.c_last_name, 
           ct.c_birth_year, coalesce(asum.address_count, 0) AS address_count,
           ss.w_warehouse_name, ss.total_sales, ss.total_tax, ss.order_count
    FROM customer_tree ct
    LEFT JOIN address_summary asum ON ct.demo_sk = asum.address_count
    LEFT JOIN sales_summary ss ON ct.c_customer_sk = ss.total_sales
)
SELECT ci.*, 
       CASE 
           WHEN ci.total_sales > 1000 THEN 'High Roller' 
           WHEN ci.total_sales BETWEEN 500 AND 1000 THEN 'Mid Tier' 
           ELSE 'Low Roller' 
       END AS customer_tier,
       CASE 
           WHEN ci.order_count IS NULL THEN 'No Orders' 
           WHEN ci.total_tax IS NULL THEN 'Tax Not Calculated' 
           ELSE NULL 
       END AS tax_status
FROM combined_info ci
ORDER BY ci.c_birth_year DESC, ci.c_first_name ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
