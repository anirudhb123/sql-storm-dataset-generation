
WITH RECURSIVE address_hierarchy AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        1 AS level
    FROM customer_address
    WHERE ca_country IS NOT NULL

    UNION ALL

    SELECT
        a.ca_address_sk,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        ah.level + 1
    FROM customer_address a
    JOIN address_hierarchy ah ON a.ca_address_sk = ah.ca_address_sk
    WHERE a.ca_state = 'NY'
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COALESCE(AVG(cd.cd_dep_count), 0) AS avg_dependents,
    STRING_AGG(DISTINCT a.ca_city, ', ') AS customer_cities,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
FROM customer c
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN address_hierarchy a ON a.ca_address_sk = c.c_current_addr_sk
WHERE (cd.cd_gender IS NOT NULL OR cd.cd_marital_status IS NOT NULL)
AND ws.ws_sold_date_sk IN (
    SELECT MAX(d.d_date_sk)
    FROM date_dim d
    WHERE d.d_year = 2023
)
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
HAVING SUM(ws.ws_net_paid) > (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2)
OR COUNT(DISTINCT ws.ws_order_number) > (
    SELECT COUNT(*) FROM customer c2
    WHERE c2.c_birth_year BETWEEN 1980 AND 1990
)
ORDER BY sales_rank DESC, total_net_paid DESC
FETCH FIRST 10 ROWS ONLY;
