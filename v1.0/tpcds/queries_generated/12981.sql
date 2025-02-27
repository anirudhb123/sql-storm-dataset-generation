
SELECT ca.city, COUNT(DISTINCT c.c_customer_id) AS customer_count
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' 
GROUP BY ca.city
ORDER BY customer_count DESC
LIMIT 10;
