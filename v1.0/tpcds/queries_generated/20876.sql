
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state
    FROM customer_address
    WHERE ca_country = 'USA'
    UNION ALL
    SELECT ca_address_sk, 
           CONCAT(ca_street_name, ' - Extended'), -- Obscure string manipulation
           ca_city, 
           ca_state
    FROM address_hierarchy
    WHERE ca_address_sk < 1000  -- Arbitrary limitation for recursion
),
sales_summary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           MAX(ws_sales_price) AS max_price,
           MIN(ws_net_paid) AS min_price
    FROM web_sales
    WHERE ws_sold_date_sk >= 20200101 -- Arbitrary date filter
    GROUP BY ws_bill_customer_sk
),
customer_demo AS (
    SELECT c.c_customer_sk,
           d.cd_gender,
           d.cd_marital_status,
           COUNT(dep.cd_demo_sk) AS dep_count
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN customer_demographics dep ON dep.cd_demo_sk = c.c_current_cdemo_sk
        AND dep.cd_dep_count IS NOT NULL
    WHERE d.cd_marital_status IS NOT NULL
    GROUP BY c.c_customer_sk, d.cd_gender, d.cd_marital_status
)
SELECT DISTINCT
    c.c_customer_id,
    a.ca_street_name,
    s.total_sales,
    cd.gender_group,
    CASE 
        WHEN cd.dep_count IS NULL THEN 'No Dependents'
        ELSE 'Has Dependents' 
    END AS dependents_status,
    CONCAT('Customer ', c.c_customer_id, ' from ', a.ca_city, ', ', a.ca_state) AS customer_location
FROM customer c
FULL OUTER JOIN address_hierarchy a ON c.c_current_addr_sk = a.ca_address_sk
JOIN sales_summary s ON s.ws_bill_customer_sk = c.c_customer_sk
JOIN (
    SELECT cd_gender,
           CASE
               WHEN cd_gender = 'M' THEN 'Male'
               WHEN cd_gender = 'F' THEN 'Female'
               ELSE 'Other'
           END AS gender_group
    FROM customer_demographics
    GROUP BY cd_gender
) cd ON cd.cd_gender = (SELECT DISTINCT d.cd_gender FROM customer_demographics d WHERE d.cd_demo_sk = c.c_current_cdemo_sk)
WHERE s.total_sales IS NOT NULL
AND a.ca_street_name IS NOT NULL
AND (cd.dep_count >= 1 OR cd.dep_count IS NULL) -- NULL logic mixed with predicates
ORDER BY total_sales DESC
LIMIT 50; -- Limiting result for benchmark purposes
