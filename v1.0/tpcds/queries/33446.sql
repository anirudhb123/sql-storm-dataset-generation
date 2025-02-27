
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT ch.c_customer_sk,
           ch.c_first_name,
           ch.c_last_name,
           ch.cd_gender,
           ch.cd_marital_status,
           ch.cd_purchase_estimate,
           level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
)

SELECT c.c_customer_id,
       ca.ca_city,
       SUM(ws.ws_sales_price) AS total_sales,
       COUNT(DISTINCT ws.ws_order_number) AS order_count,
       MAX(ws.ws_net_paid) AS max_net_paid,
       MIN(ws.ws_net_paid) AS min_net_paid,
       CASE WHEN cd.cd_gender = 'F' THEN 'Female Customer'
            WHEN cd.cd_gender = 'M' THEN 'Male Customer'
            ELSE 'Other' END AS gender_desc,
       ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_sales_price) DESC) AS city_rank
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_hierarchy ch ON c.c_customer_sk = ch.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
WHERE ca.ca_country = 'USA'
AND ws.ws_sales_price > 0
GROUP BY c.c_customer_id, ca.ca_city, cd.cd_gender
HAVING SUM(ws.ws_sales_price) > 1000
ORDER BY total_sales DESC, order_count DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
