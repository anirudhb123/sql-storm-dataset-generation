
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
    WHERE ca_city IS NOT NULL AND ca_state IS NOT NULL
),
CustomerSummary AS (
    SELECT
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregatedData AS (
    SELECT
        ad.full_address,
        SUM(CASE WHEN cs.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cs.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        AVG(cd.cd_dep_count) AS average_dependents
    FROM AddressDetails ad
    JOIN CustomerSummary cs ON cs.c_customer_sk IN (
        SELECT c.c_customer_sk 
        FROM customer c 
        WHERE c.c_current_addr_sk = ad.ca_address_sk
    )
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY ad.full_address
)
SELECT 
    full_address, 
    male_count, 
    female_count, 
    average_dependents,
    RANK() OVER (ORDER BY male_count DESC, female_count DESC) AS address_rank
FROM 
    AggregatedData
WHERE 
    average_dependents > 0
ORDER BY 
    address_rank, full_address;
