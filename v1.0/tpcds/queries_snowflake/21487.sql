
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           CAST(COALESCE(SUBSTRING(c.c_email_address, 1, 3), 'N/A') AS VARCHAR(10)) AS email_prefix,
           CASE WHEN cd.cd_purchase_estimate IS NULL THEN 'Unspecified'
                WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
                WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
                WHEN cd.cd_purchase_estimate > 5000 THEN 'High'
           END AS purchase_band
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_month IN (1, 2, 3)
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           CAST(COALESCE(SUBSTRING(c.c_email_address, 1, 3), 'N/A') AS VARCHAR(10)) AS email_prefix,
           CASE WHEN cd.cd_purchase_estimate IS NULL THEN 'Unspecified'
                WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
                WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
                WHEN cd.cd_purchase_estimate > 5000 THEN 'High'
           END AS purchase_band
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT w.w_warehouse_name, 
       SUM(ws.ws_quantity) AS total_quantity, 
       AVG(ws.ws_net_paid) AS avg_net_paid,
       LISTAGG(DISTINCT ch.email_prefix, ', ') WITHIN GROUP (ORDER BY ch.email_prefix) AS unique_email_prefixes,
       COUNT(DISTINCT ch.c_customer_sk) AS customer_count,
       COUNT(DISTINCT CASE WHEN ch.purchase_band = 'High' THEN ch.c_customer_sk END) AS high_value_customers
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN CustomerHierarchy ch ON ws.ws_bill_customer_sk = ch.c_customer_sk
WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
AND (ws.ws_net_paid_inc_tax IS NOT NULL OR ws.ws_net_paid_inc_ship IS NULL)
GROUP BY w.w_warehouse_name
HAVING AVG(ws.ws_net_paid) > (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2 WHERE ws2.ws_sold_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023))
ORDER BY total_quantity DESC;
