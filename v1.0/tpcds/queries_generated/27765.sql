
WITH customer_info AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           ca.ca_city, 
           ca.ca_state, 
           ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_sales AS (
    SELECT ws.ws_bill_customer_sk, 
           SUM(ws.ws_ext_sales_price) AS total_sales, 
           COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
customers_sales AS (
    SELECT ci.full_name, 
           ci.ca_city, 
           ci.ca_state, 
           ci.ca_country, 
           is.total_sales,
           is.total_orders
    FROM customer_info ci
    LEFT JOIN item_sales is ON ci.c_customer_sk = is.ws_bill_customer_sk
)
SELECT full_name, 
       ca_city, 
       ca_state, 
       ca_country, 
       COALESCE(total_sales, 0) AS total_sales, 
       COALESCE(total_orders, 0) AS total_orders,
       CASE 
           WHEN total_sales IS NULL THEN 'No Purchases'
           WHEN total_sales > 1000 THEN 'High Value Customer'
           WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_value_category
FROM customers_sales
ORDER BY total_sales DESC, full_name;
