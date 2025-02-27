
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, ca_street_name,
           ROW_NUMBER() OVER(PARTITION BY ca_state ORDER BY ca_city) AS rank
    FROM customer_address
    WHERE ca_country IS NOT NULL
      AND (ca_city LIKE 'San%' OR ca_city LIKE '%ville')
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM web_sales
    WHERE ws_sales_price > (SELECT AVG(ws_sales_price) 
                             FROM web_sales 
                             WHERE ws_sold_date_sk BETWEEN 10000 AND 10010)
    GROUP BY ws_bill_customer_sk
),
demographics AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status,
           SUM(CASE WHEN cd_purchase_estimate IS NULL THEN 0 ELSE cd_purchase_estimate END) AS total_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
),
full_customer_info AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, s.total_sales,
           d.total_purchase_estimate, a.ca_city, a.ca_state 
    FROM customer c
    LEFT JOIN sales_summary s ON c.c_customer_sk = s.ws_bill_customer_sk
    LEFT JOIN demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN address_cte a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    COALESCE(f.total_sales, 0) AS net_sales,
    COALESCE(f.total_purchase_estimate, 0) AS purchase_estimate,
    COUNT(DISTINCT a.ca_address_sk) OVER(PARTITION BY f.ca_state) AS unique_addresses_per_state,
    CASE
        WHEN f.total_sales IS NULL AND (f.ca_city IS NOT NULL OR f.ca_state IS NOT NULL) THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_indicator
FROM full_customer_info f
LEFT JOIN customer_address a ON f.ca_city = a.ca_city AND f.ca_state = a.ca_state
WHERE f.total_sales > (SELECT AVG(total_sales) FROM full_customer_info WHERE total_sales IS NOT NULL)
OR f.ca_state IN (SELECT ca_state FROM customer_address GROUP BY ca_state HAVING COUNT(*) > 10)
ORDER BY f.total_sales DESC, f.ca_state, f.c_last_name;
