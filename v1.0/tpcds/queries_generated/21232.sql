
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address, 
           ca_city, ca_state, ca_zip, ca_country 
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, CONCAT(a.ca_street_number, ' Apt ', a.ca_suite_number, ', ', a.ca_street_name, ' ', a.ca_street_type) AS full_address, 
           a.ca_city, a.ca_state, a.ca_zip, a.ca_country 
    FROM customer_address a
    INNER JOIN address_hierarchy ah ON a.ca_address_sk = ah.ca_address_sk
    WHERE a.ca_suite_number IS NOT NULL
),
customer_stats AS (
    SELECT c.c_customer_sk, 
           MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
           MIN(cd.cd_dep_count) AS min_dep_count,
           AVG(cd.cd_dep_employed_count) AS avg_dep_employed
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
sales_data AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
completed_sales AS (
    SELECT s.ss_store_sk, 
           COUNT(ss_ticket_number) AS sales_count,
           STRING_AGG(DISTINCT CONCAT_WS(', ', ss_item_sk, ss_ext_sales_price), '; ') AS item_details
    FROM store_sales s
    LEFT JOIN store_returns sr ON s.ss_ticket_number = sr.sr_ticket_number
    GROUP BY s.ss_store_sk
)
SELECT a.full_address, c.max_purchase_estimate, c.min_dep_count, s.total_sales, coalesce(cr.cr_return_amount, 0) AS total_return_amount, cs.sales_count, cs.item_details
FROM address_hierarchy a
JOIN customer_stats c ON a.ca_address_sk = c.c_customer_sk
JOIN sales_data s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk AND cr.cr_return_quantity > 0
JOIN completed_sales cs ON a.ca_address_sk = cs.ss_store_sk
WHERE a.ca_state = 'CA' 
  AND (c.max_purchase_estimate > 1000 OR c.min_dep_count IS NULL)
  AND (s.total_sales > 5000 OR (cs.sales_count IS NULL AND cs.item_details IS NOT NULL))
ORDER BY a.full_address, c.max_purchase_estimate DESC;
