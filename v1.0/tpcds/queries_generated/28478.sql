
WITH address_counts AS (
    SELECT ca_state, COUNT(*) AS address_count
    FROM customer_address
    GROUP BY ca_state
),
demographics AS (
    SELECT cd_gender, cd_marital_status, SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
joined_data AS (
    SELECT ca.ca_state, d.cd_gender, d.cd_marital_status, d.total_purchase_estimate, ac.address_count
    FROM address_counts ac
    JOIN demographics d ON d.cd_marital_status = 'M'
    JOIN customer c ON c.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = ac.ca_state)
)
SELECT 
    jd.ca_state,
    jd.cd_gender,
    jd.cd_marital_status,
    jd.total_purchase_estimate,
    jd.address_count,
    CONCAT(jd.ca_state, ' - ', jd.cd_gender, ' - ', jd.cd_marital_status) AS demographic_key,
    LENGTH(demographic_key) AS key_length
FROM joined_data jd
WHERE jd.address_count > 100
ORDER BY jd.ca_state, jd.cd_gender, jd.cd_marital_status;
