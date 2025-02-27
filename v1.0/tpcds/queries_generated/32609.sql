
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)
SELECT 
    ca.ca_address_id,
    ca.ca_city,
    cd.cd_gender,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_profit) AS total_profit,
    DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_net_profit) DESC) AS city_rank
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    (SELECT DISTINCT c_customer_sk, MAX(level) AS max_level 
     FROM customer_hierarchy 
     GROUP BY c_customer_sk) ch ON c.c_customer_sk = ch.c_customer_sk
WHERE 
    cd.cd_gender IS NOT NULL
    AND (cd.cd_marital_status = 'M' OR ch.max_level > 0)
    AND ws.ws_sales_price > 100.00
GROUP BY 
    ca.ca_address_id, ca.ca_city, cd.cd_gender
HAVING 
    total_quantity > (SELECT AVG(total_qty) FROM (
        SELECT SUM(ws_quantity) AS total_qty
        FROM web_sales
        GROUP BY ws_ship_customer_sk) AS avg_total)
ORDER BY 
    total_profit DESC;
