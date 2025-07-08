
SELECT
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    LISTAGG(DISTINCT cd.cd_marital_status, ', ') WITHIN GROUP (ORDER BY cd.cd_marital_status) AS unique_marital_statuses,
    MAX(cd.cd_dep_count) AS max_dependencies,
    MIN(cd.cd_dep_employed_count) AS min_employed_dependencies
FROM
    customer_address ca
JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE
    ca.ca_city IS NOT NULL
    AND ca.ca_state IS NOT NULL
GROUP BY
    ca.ca_city, ca.ca_state
ORDER BY
    total_customers DESC
LIMIT 100;
