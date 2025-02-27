
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, c_salutation, 1 AS hierarchy_level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, c.c_salutation, ch.hierarchy_level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk AND c.c_customer_sk <> ch.c_customer_sk
),
item_sales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sales, AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
customer_sales AS (
    SELECT c.c_customer_sk, SUM(ws.ws_net_paid) AS total_net_paid
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cs.total_net_paid,
           RANK() OVER (ORDER BY cs.total_net_paid DESC) AS customer_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_net_paid IS NOT NULL
),
join_with_address AS (
    SELECT tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_net_paid, ca.ca_city
    FROM top_customers tc
    LEFT JOIN customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
    WHERE tc.customer_rank <= 10
)
SELECT j.c_customer_sk, j.c_first_name, j.c_last_name, COALESCE(j.total_net_paid, 0) AS total_net_paid,
       COALESCE(j.ca_city, 'Unknown') AS city,
       ISNULL(ih.total_sales, 0) AS total_sales, ISNULL(ih.avg_sales_price, 0) AS avg_price
FROM join_with_address j
LEFT JOIN item_sales ih ON j.c_customer_sk = ih.ws_item_sk
ORDER BY j.total_net_paid DESC, j.c_first_name;
