
WITH RECURSIVE SalesHierarchy AS (
    SELECT ws_order_number, ws_item_sk, ws_quantity, ws_ext_sales_price, 1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459200 AND 2459207
    UNION ALL
    SELECT ws.ws_order_number, ws.ws_item_sk, 
           ws.ws_quantity + sh.ws_quantity, 
           ws.ws_ext_sales_price + sh.ws_ext_sales_price, 
           sh.level + 1
    FROM web_sales ws
    JOIN SalesHierarchy sh ON ws.ws_order_number = sh.ws_order_number 
    WHERE sh.level < 3
), 
CustomerStats AS (
    SELECT c.c_customer_sk,
           MAX(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
           MAX(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
           SUM(SH.ws_quantity) AS total_quantity,
           SUM(SH.ws_ext_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN SalesHierarchy SH ON c.c_customer_sk = SH.ws_order_number
    GROUP BY c.c_customer_sk
)
SELECT ca.ca_city, 
       COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
       SUM(cs.total_quantity) AS total_quantity,
       AVG(cs.total_sales) AS average_sales
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
WHERE ca.ca_state = 'CA' AND cs.total_sales IS NOT NULL
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT cs.c_customer_sk) > 10
ORDER BY average_sales DESC;
