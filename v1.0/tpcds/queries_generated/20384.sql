
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL

    UNION ALL

    SELECT a.ca_address_sk, CONCAT('Nested ', a.ca_street_name) AS ca_street_name, a.ca_city, a.ca_state, level + 1
    FROM customer_address a
    JOIN address_hierarchy ah ON a.ca_state = ah.ca_state AND a.ca_city <> ah.ca_city
    WHERE level < 3
),
customer_with_details AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_day, c.c_birth_month,
           d.d_year, d.d_month_seq, d.d_day_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_year DESC, d.d_month_seq DESC) AS rn
    FROM customer c
    LEFT JOIN date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
),
sales_summary AS (
    SELECT 
        SUM(ws_net_paid) AS total_sales, 
        SUM(ws_quantity) AS total_quantity, 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 10000 AND 20000
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ah.ca_street_name,
    ah.ca_city,
    ah.ca_state,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COUNT(DISTINCT wcr.wr_order_number) AS web_returns,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_returns,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    MAX(CASE WHEN ss.avg_sales_price > 50 THEN 'High Value' 
             WHEN ss.avg_sales_price <= 50 AND ss.avg_sales_price IS NOT NULL THEN 'Medium Value' 
             ELSE 'Low Value' END) AS customer_value
FROM customer_with_details c
JOIN address_hierarchy ah ON c.c_current_addr_sk = ah.ca_address_sk
LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE c.c_birth_year IS NOT NULL
AND ah.level = 2
AND c.c_first_shipto_date_sk IS NOT NULL
GROUP BY c.c_first_name, c.c_last_name, ah.ca_street_name, ah.ca_city, ah.ca_state, ss.total_sales, ss.total_quantity
HAVING SUM(COALESCE(ss.total_quantity, 0)) > 10
ORDER BY total_sales DESC
LIMIT 100;
