
WITH CustomerData AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ProcessedData AS (
    SELECT
        *,
        LENGTH(full_name) AS name_length,
        LOWER(full_name) AS name_lower,
        UPPER(full_name) AS name_upper,
        REPLACE(full_name, ' ', '-') AS name_with_hyphens
    FROM
        CustomerData
),
AggregatedData AS (
    SELECT
        ca_state,
        COUNT(*) AS total_customers,
        AVG(name_length) AS avg_name_length
    FROM
        ProcessedData
    GROUP BY
        ca_state
)
SELECT
    ad.ca_state,
    agg.total_customers,
    agg.avg_name_length,
    STRING_AGG(ad.full_name || ' (' || ad.cd_gender || ')', '; ') AS customer_names
FROM
    ProcessedData ad
JOIN
    AggregatedData agg ON ad.ca_state = agg.ca_state
GROUP BY
    ad.ca_state, agg.total_customers, agg.avg_name_length
ORDER BY
    ad.ca_state ASC;
