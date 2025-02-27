
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state, ca_zip, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT ca.ca_address_sk, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_city = ah.ca_city
    WHERE ca.ca_address_sk <> ah.ca_address_sk
),

customer_income AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk,
           CASE 
               WHEN cd.cd_purchase_estimate IS NULL THEN 0 
               ELSE cd.cd_purchase_estimate 
           END AS adjusted_purchase_estimate
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk IS NOT NULL
),

sales_summary AS (
    SELECT ws_bill_customer_sk, SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS orders_count,
           DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),

final_report AS (
    SELECT c.c_customer_id, 
           ca.ca_street_name, 
           ca.ca_city, 
           ca.ca_state,
           cos.co_count,
           coalesce(cs.total_sales, 0) AS total_sales,
           sys.num_customers,
           CASE 
               WHEN cs.total_sales > 1000 THEN 'High'
               WHEN cs.total_sales > 0 THEN 'Medium'
               ELSE 'Low' 
           END AS sales_category
    FROM customer c
    LEFT JOIN customer_income ci ON c.c_current_cdemo_sk = ci.cd_demo_sk
    LEFT JOIN address_hierarchy ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN (
        SELECT COUNT(DISTINCT ws_bill_customer_sk) AS co_count
        FROM web_sales
        WHERE ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type LIKE '%Express%')
    ) cos ON TRUE
    LEFT JOIN sales_summary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
    LEFT JOIN (
        SELECT COUNT(DISTINCT c_customer_sk) AS num_customers
        FROM customer
        WHERE c_first_name IS NOT NULL OR c_last_name IS NOT NULL
    ) sys ON TRUE
    WHERE ci.adjusted_purchase_estimate IS NOT NULL
      AND (ca.ca_state = 'CA' OR ca.ca_zip IS NULL)

)
SELECT * FROM final_report
WHERE sales_category = 'High' 
ORDER BY total_sales DESC
LIMIT 10;
