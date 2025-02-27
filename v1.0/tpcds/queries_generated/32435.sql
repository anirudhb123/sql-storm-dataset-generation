
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_customer_sk
),
item_stats AS (
    SELECT i.i_item_sk, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_quantity) AS total_quantity,
           AVG(ws.ws_sales_price) AS avg_sales_price
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk
),
sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_year
),
customer_info AS (
    SELECT ca.ca_city, 
           SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ca.ca_city
)
SELECT 
    d.d_year,
    cs.ca_city,
    cs.total_spent,
    ss.total_sales,
    ss.total_profit,
    iss.total_orders,
    iss.total_quantity,
    iss.avg_sales_price
FROM sales_summary ss
JOIN customer_info cs ON ss.total_sales > 1000000
JOIN item_stats iss ON iss.total_quantity > 0
LEFT JOIN date_dim d ON d.d_year = ss.d_year
WHERE cs.total_spent IS NOT NULL
ORDER BY d.d_year DESC, cs.total_spent DESC
LIMIT 10;
