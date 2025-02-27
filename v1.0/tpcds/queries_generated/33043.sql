
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state, ca_zip, ca_country, 0 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT a.ca_address_sk, a.ca_street_name, a.ca_city, a.ca_state, a.ca_zip, a.ca_country, ah.level + 1
    FROM customer_address a
    JOIN address_hierarchy ah ON a.ca_city = ah.ca_city AND a.ca_state = ah.ca_state
    WHERE ah.level < 5
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
           cd.cd_marital_status, cd.cd_purchase_estimate, 
           address_hierarchy.ca_city, address_hierarchy.ca_state
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN address_hierarchy ON c.c_current_addr_sk = address_hierarchy.ca_address_sk
),
sales_summary AS (
    SELECT c.c_customer_sk, SUM(ws.ws_sales_price) AS total_sales, COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer_info c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
ranked_customers AS (
    SELECT c.*, 
           ROW_NUMBER() OVER (PARTITION BY c.ca_state ORDER BY s.total_sales DESC) AS sales_rank,
           SUM(s.total_sales) OVER (PARTITION BY c.ca_state) AS state_total_sales
    FROM customer_info c
    JOIN sales_summary s ON c.c_customer_sk = s.c_customer_sk
)
SELECT r.c_first_name, r.c_last_name, r.ca_city, r.ca_state, 
       r.total_sales, r.order_count, r.sales_rank, r.state_total_sales
FROM ranked_customers r
WHERE r.sales_rank <= 10 
AND r.c_gender = 'F'
ORDER BY r.ca_state, r.sales_rank;
