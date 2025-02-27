
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_country, ca_state, ca_county, ca_city, ca_street_name, 
           ca_street_type, ca_street_number, 1 AS depth
    FROM customer_address
    WHERE ca_country IS NOT NULL
    
    UNION ALL
    
    SELECT ca_address_sk, ca_country, ca_state, ca_county, ca_city, 
           CONCAT(ca_street_name, ' ', ca_street_type, ' ', ca_street_number) AS full_address,
           CONCAT('Depth: ', depth + 1) AS depth
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_state = ah.ca_state AND ca.ca_county = ah.ca_county
    WHERE ah.depth < 2
)
SELECT 
    a.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    AVG(d.d_year) AS avg_year_of_interaction,
    MAX(i.i_current_price) AS max_item_price,
    STRING_AGG(DISTINCT CONCAT(p.p_promo_name, ': ', p.p_cost), ', ') AS promotions_used
FROM customer c
LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN address_hierarchy ah ON a.ca_address_sk = ah.ca_address_sk
WHERE a.ca_country IS NOT NULL
AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status <> 'S')
AND (d.d_year BETWEEN 2015 AND 2020)
GROUP BY a.ca_city
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY avg_year_of_interaction DESC
LIMIT 5;
