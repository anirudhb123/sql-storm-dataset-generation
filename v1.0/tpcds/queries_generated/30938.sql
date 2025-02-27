
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.cd_demo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT 
    ca.ca_city,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_profit,
    COUNT(DISTINCT ch.c_customer_sk) AS customer_count,
    CASE 
        WHEN SUM(ws.ws_sales_price) > 10000 THEN 'High Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM web_sales ws
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN CustomerHierarchy ch ON ch.c_customer_sk = ws.ws_bill_customer_sk
WHERE ca.ca_state = 'NY'
AND (ws.ws_sales_price IS NOT NULL OR ws.ws_net_profit IS NOT NULL)
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY total_sales DESC
LIMIT 10;
