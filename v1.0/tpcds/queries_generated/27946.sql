
WITH processed_customer AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS domain,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown' 
        END AS gender_description,
        CONCAT_WS(', ', ca.ca_city, ca.ca_state) AS address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE LENGTH(c.c_email_address) > 5
),
aggregated_data AS (
    SELECT 
        gender_description,
        COUNT(*) AS count_customers,
        COUNT(DISTINCT domain) AS unique_domains,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM processed_customer pc
    JOIN customer_demographics cd ON pc.c_customer_id = cd.cd_demo_sk
    GROUP BY gender_description
)
SELECT 
    gender_description,
    count_customers,
    unique_domains,
    avg_purchase_estimate,
    (count_customers * 100.0 / SUM(count_customers) OVER ()) AS percentage_of_total
FROM aggregated_data
ORDER BY count_customers DESC;
