
SELECT
    ca_city,
    ca_state,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_customers,
    STRING_AGG(DISTINCT cd_education_status, ', ') AS unique_education_levels,
    STRING_AGG(DISTINCT c.c_first_name || ' ' || c.c_last_name, '; ') AS customer_names
FROM
    customer_address ca
JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY
    ca_city, ca_state
HAVING
    COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY
    total_customers DESC;
