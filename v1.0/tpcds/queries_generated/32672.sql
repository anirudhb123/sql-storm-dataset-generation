
WITH RECURSIVE customer_summary AS (
    SELECT c_customer_sk, c_first_name, c_last_name, cd_demo_sk, 
           cd_gender, cd_marital_status, cd_purchase_estimate, 
           1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd_purchase_estimate > 1000
    
    UNION ALL
    
    SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name, 
           cs.cd_demo_sk, cs.cd_gender, cs.cd_marital_status, 
           cs.cd_purchase_estimate, cs.level + 1
    FROM customer_summary cs
    JOIN customer c ON cs.c_customer_sk = c.c_current_addr_sk
)

SELECT ca.city AS address_city, 
       SUM(ws.ws_net_paid) AS total_sales,
       AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
       COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM customer c
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws ON (c.c_customer_sk = ws.ws_bill_customer_sk OR c.c_customer_sk = ws.ws_ship_customer_sk)
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE cd.cd_marital_status = 'M'
AND cd.cd_gender = 'F'
AND EXISTS (SELECT 1 FROM customer_summary cs 
            WHERE cs.c_customer_sk = c.c_customer_sk)
GROUP BY ca.city
HAVING total_sales > 5000
ORDER BY total_sales DESC
LIMIT 10
```
