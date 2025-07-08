
WITH RECURSIVE Address_CTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip, 1 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_zip, c.level + 1
    FROM customer_address a
    JOIN Address_CTE c ON a.ca_city = c.ca_city AND a.ca_state = c.ca_state AND a.ca_zip <> c.ca_zip
    WHERE a.ca_city IS NOT NULL
),
Customer_Info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent,
           COUNT(DISTINCT ws.ws_order_number) AS web_orders,
           COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
           COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
Sales_Summary AS (
    SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status,
           ai.ca_city, ai.ca_state, ai.ca_zip, ci.total_spent,
           CASE 
               WHEN ci.total_spent > 1000 THEN 'High Spender'
               WHEN ci.total_spent BETWEEN 500 AND 1000 THEN 'Medium Spender'
               ELSE 'Low Spender'
           END AS spending_category
    FROM Customer_Info ci
    JOIN Address_CTE ai ON ci.c_customer_sk = ai.ca_address_sk
)
SELECT s.c_first_name, s.c_last_name, s.cd_gender, s.spending_category,
       COUNT(*) AS customer_count,
       AVG(s.total_spent) AS avg_spent
FROM Sales_Summary s
GROUP BY s.c_first_name, s.c_last_name, s.cd_gender, s.spending_category
HAVING COUNT(*) > 1 
ORDER BY avg_spent DESC
LIMIT 10;
