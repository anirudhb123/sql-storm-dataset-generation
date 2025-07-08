
WITH CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ws.ws_net_profit) AS total_net_profit,
    MAX(ws.ws_sales_price) AS max_sales_price,
    LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY c.c_first_name, c.c_last_name) AS customer_names,
    CAST('2002-10-01' AS DATE) AS report_date
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE ca.ca_city IS NOT NULL
AND cd.cd_gender = 'M'
AND cd.cd_marital_status = 'S'
AND (cd.cd_purchase_estimate IS NOT NULL AND cd.cd_purchase_estimate > 1000)
GROUP BY ca.ca_city
ORDER BY total_net_profit DESC
LIMIT 10;
