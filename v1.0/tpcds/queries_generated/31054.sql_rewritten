WITH RECURSIVE SalesHierarchy AS (
    SELECT s_store_sk,
           s_store_name,
           s_number_employees AS employee_count,
           s_floor_space,
           0 AS level
    FROM store
    WHERE s_store_sk IS NOT NULL

    UNION ALL

    SELECT sh.s_store_sk,
           sh.s_store_name,
           sh.employee_count + s.s_number_employees,
           sh.s_floor_space + s.s_floor_space,
           sh.level + 1
    FROM SalesHierarchy sh
    JOIN store s ON sh.s_store_sk = s.s_store_sk
    WHERE sh.level < 3 
)

SELECT ca.ca_city,
       COUNT(DISTINCT c.c_customer_id) AS total_customers,
       SUM(ws.ws_net_profit) AS total_net_profit,
       AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
       MAX(ws.ws_sales_price) AS max_sales_price,
       MIN(ws.ws_sales_price) AS min_sales_price,
       STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN SalesHierarchy sh ON sh.s_store_sk = c.c_current_addr_sk
WHERE (ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231 
       OR ws.ws_sold_date_sk IS NULL)
  AND cd.cd_gender = 'F'
  AND (cd.cd_purchase_estimate > (SELECT AVG(cd2.cd_purchase_estimate) 
                                     FROM customer_demographics cd2 
                                     WHERE cd2.cd_gender = 'F'))
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY total_net_profit DESC
LIMIT 10;