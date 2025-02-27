
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_street_number, ca_street_name, ca_city, ca_state, 0 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_state = ah.ca_state AND ca.ca_city != ah.ca_city
    WHERE ah.level < 3
),
navigable_customers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name,
           c.c_last_name,
           COALESCE(cd.cd_gender, 'U') AS gender,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_month DESC) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
detailed_sales AS (
    SELECT DISTINCT
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 0 
            ELSE ws.ws_sales_price 
        END AS sales_price,
        CASE 
            WHEN ss.ss_net_profit IS NOT NULL THEN ss.ss_net_profit 
            ELSE 0 
        END AS net_profit,
        CASE 
            WHEN cs.cs_net_paid IS NULL THEN -1 * COALESCE(NULLIF(cs.cs_ext_discount_amt, 0), 1) 
            ELSE cs.cs_net_paid 
        END AS adjusted_net_paid,
        d.d_date AS sale_date
    FROM web_sales ws
    FULL OUTER JOIN store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    FULL OUTER JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE (adjusted_net_paid < 0 OR net_profit < 0 OR sales_price = 0)
),
sales_summary AS (
    SELECT ca.ca_city,
           SUM(d.sales_price) AS total_sales_price,
           SUM(s.net_profit) AS total_net_profit,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM detailed_sales d
    JOIN navigable_customers c ON d.sale_date = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_city
    USING (total_sales_price, total_net_profit)
)
SELECT ss.ca_city, 
       CASE 
           WHEN ss.total_net_profit < 0 THEN 'Performance Issue'
           ELSE 'Normal'
       END AS status,
       (SELECT MAX(total_net_profit) FROM sales_summary) AS max_profit
FROM sales_summary ss
WHERE ss.customer_count > (
    SELECT AVG(customer_count) FROM sales_summary
)
ORDER BY ss.total_sales_price DESC, ss.ca_city
LIMIT 10;
