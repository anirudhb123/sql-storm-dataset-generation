
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregateValues AS (
    SELECT 
        ci.ca_city AS city,
        ci.ca_state AS state,
        COUNT(*) AS total_customers,
        SUM(ci.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT ci.cd_gender, ', ') AS unique_genders,
        STRING_AGG(DISTINCT ci.cd_marital_status, ', ') AS unique_marital_status
    FROM CustomerInfo ci
    GROUP BY ci.ca_city, ci.ca_state
)
SELECT 
    city,
    state,
    total_customers,
    total_purchase_estimate,
    avg_purchase_estimate,
    SPLIT_PART(unique_genders, ',', 1) AS first_gender,
    SPLIT_PART(unique_marital_status, ',', 1) AS first_marital_status
FROM AggregateValues
WHERE total_customers > 100
ORDER BY total_purchase_estimate DESC;
