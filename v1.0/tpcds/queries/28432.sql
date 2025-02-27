
WITH AddressDetails AS (
    SELECT
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FilteredAddresses AS (
    SELECT
        full_name,
        full_address,
        ca_city,
        ca_state,
        ca_zip,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM
        AddressDetails
    WHERE
        rn = 1
        AND (cd_gender = 'F' OR cd_marital_status = 'M')
),
AddressStatistics AS (
    SELECT
        ca_state,
        COUNT(*) AS total_customers,
        COUNT(DISTINCT ca_city) AS unique_cities,
        STRING_AGG(full_address, '; ') AS all_addresses
    FROM
        FilteredAddresses
    GROUP BY
        ca_state
)
SELECT
    ca_state,
    total_customers,
    unique_cities,
    all_addresses,
    CASE
        WHEN total_customers > 100 THEN 'High'
        WHEN total_customers BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS customer_density
FROM
    AddressStatistics
ORDER BY
    customer_density DESC, total_customers DESC;
