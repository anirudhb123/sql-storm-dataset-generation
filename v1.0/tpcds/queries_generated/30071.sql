
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 1 AS level
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
    WHERE sh.level < 5
),
customer_totals AS (
    SELECT sh.c_customer_sk, 
           sh.c_first_name,
           sh.c_last_name,
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM sales_hierarchy sh
    LEFT JOIN web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name
),
top_customers AS (
    SELECT *
    FROM customer_totals
    WHERE total_net_profit > (
        SELECT AVG(total_net_profit) 
        FROM customer_totals
    )
),
address_info AS (
    SELECT ca.ca_address_sk,
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM customer_address ca
    WHERE ca.ca_country = 'USA'
)
SELECT tc.c_first_name,
       tc.c_last_name,
       tc.total_net_profit,
       tc.total_orders,
       ai.full_address,
       ROW_NUMBER() OVER (PARTITION BY ai.full_address ORDER BY tc.total_net_profit DESC) AS rank
FROM top_customers tc
JOIN address_info ai ON tc.c_customer_sk = ai.ca_address_sk
ORDER BY tc.total_net_profit DESC, tc.total_orders DESC
FETCH FIRST 10 ROWS ONLY;
