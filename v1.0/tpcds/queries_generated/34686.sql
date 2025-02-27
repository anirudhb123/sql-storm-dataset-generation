
WITH RECURSIVE SalesHierarchy AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_profit, 1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT ws.sold_date_sk, ws.item_sk, ws.quantity, ws.net_profit, h.level + 1
    FROM web_sales ws
    JOIN SalesHierarchy h ON ws.item_sk = h.ws_item_sk
    WHERE h.level < 5
),
CustomerDetails AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status,
           SUM(sh.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales sh ON c.c_customer_sk = sh.ws_ship_customer_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'S'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, 
             cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT c.*, 
           ROW_NUMBER() OVER (PARTITION BY c.cd_gender ORDER BY c.total_net_profit DESC) AS rank
    FROM CustomerDetails c
)
SELECT 
    ca.ca_address_id, 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT tc.c_customer_sk) AS num_customers,
    SUM(sh.ws_net_profit) AS total_sales
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN TopCustomers tc ON c.c_customer_sk = tc.c_customer_sk AND tc.rank <= 5
LEFT JOIN web_sales sh ON c.c_customer_sk = sh.ws_ship_customer_sk
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT tc.c_customer_sk) > 0
ORDER BY total_sales DESC
LIMIT 10;
