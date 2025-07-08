
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 0 AS level
    FROM customer c
    WHERE c.c_customer_id = 'C000000001'
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
address_info AS (
    SELECT ca.ca_address_sk, ca.ca_country, ca.ca_city
    FROM customer_address ca
    WHERE ca.ca_country IS NOT NULL
),
customer_metrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.average_order_value, 0) AS average_order_value,
        a.ca_country,
        a.ca_city
    FROM customer c
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN address_info a ON c.c_current_addr_sk = a.ca_address_sk
),
top_customers AS (
    SELECT
        customer_metrics.*,
        RANK() OVER (ORDER BY customer_metrics.total_sales DESC) AS sales_rank
    FROM customer_metrics
)
SELECT 
    th.c_customer_sk,
    th.c_first_name,
    th.c_last_name,
    th.total_sales,
    th.total_orders,
    th.average_order_value,
    th.ca_country,
    th.ca_city,
    ch.level AS customer_level
FROM top_customers th
LEFT JOIN customer_hierarchy ch ON th.c_customer_sk = ch.c_customer_sk
WHERE th.sales_rank <= 10 
ORDER BY th.total_sales DESC;
