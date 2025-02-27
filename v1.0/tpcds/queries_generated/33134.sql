
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           coalesce(cdv.cc_call_center_sk, -1) AS call_center_sk
    FROM customer c
    LEFT JOIN call_center cdv ON c.c_current_hdemo_sk = cdv.cc_call_center_sk
    WHERE c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           coalesce(cdv.cc_call_center_sk, -1) AS call_center_sk
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.call_center_sk = c.c_current_hdemo_sk
)

SELECT 
    ca.ca_country,
    cd.cd_gender,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_net_paid) AS total_net_paid,
    DENSE_RANK() OVER (PARTITION BY ca.ca_country ORDER BY SUM(ws.ws_net_paid) DESC) AS country_sales_rank
FROM customer_address ca
JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE ca.ca_country IS NOT NULL 
AND cd.cd_gender IN ('M', 'F') 
AND ws.ws_sold_date_sk >= (
    SELECT MAX(d.d_date_sk) 
    FROM date_dim d 
    WHERE d.d_year = 2023 AND d.d_month_seq <= 6
)
GROUP BY ca.ca_country, cd.cd_gender
HAVING SUM(ws.ws_net_paid) > (SELECT AVG(total_net) FROM (
    SELECT SUM(ws.ws_net_paid) AS total_net
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
) AS avg_sales)
ORDER BY country_sales_rank, total_customers DESC
LIMIT 10;
