
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    INNER JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)

SELECT 
    ca.city,
    ca.state,
    COUNT(DISTINCT c.customer_sk) AS unique_customers,
    SUM(ws.net_profit) AS total_profit,
    AVG(ws.net_paid) AS avg_payment,
    MAX(ws_sold_date_sk) AS last_order_date,
    STRING_AGG(DISTINCT cd.education_status, ', ') AS education_levels,
    RANK() OVER (PARTITION BY ca.state ORDER BY SUM(ws.net_profit) DESC) AS state_rank
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE 
    ca.state IS NOT NULL
    AND ws.ws_sold_date_sk > (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = (SELECT MAX(d_year) FROM date_dim) - 1
    )
    AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
GROUP BY ca.city, ca.state
HAVING COUNT(DISTINCT c.customer_sk) > 10
ORDER BY total_profit DESC;
