
WITH RECURSIVE SalesHierarchy AS (
    SELECT s_store_sk, ss_ticket_number, ss_item_sk, ss_quantity, ss_sales_price, 1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)

    UNION ALL

    SELECT sh.s_store_sk, ss.ss_ticket_number, ss.ss_item_sk, 
           ss.ss_quantity + sh.ss_quantity, 
           (ss.ss_sales_price + sh.ss_sales_price) / 2, 
           sh.level + 1
    FROM SalesHierarchy sh
    JOIN store_sales ss ON sh.ss_ticket_number = ss.ss_ticket_number
    WHERE sh.level < 3
)
SELECT ca.ca_city,
       COUNT(DISTINCT c.c_customer_sk) AS total_customers,
       SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_profit,
       SUM(COALESCE(cs.cs_net_profit, 0)) AS total_catalog_profit,
       SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_profit,
       RANK() OVER (ORDER BY SUM(COALESCE(ws.ws_net_profit, 0)) DESC) AS city_rank
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN SalesHierarchy sh ON ss.ss_ticket_number = sh.ss_ticket_number
WHERE ca.ca_state = 'CA'
  AND (c.c_birth_year >= 1970 OR c.c_birth_year IS NULL)
  AND (c.c_preferred_cust_flag = 'Y' OR c.c_current_cdemo_sk IS NULL)
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY total_web_profit DESC, city_rank ASC
LIMIT 10;
