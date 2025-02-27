
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS address_rank
    FROM customer_address
),
FilteredAddresses AS (
    SELECT 
        full_address,
        ca_city,
        ca_state
    FROM RankedAddresses
    WHERE address_rank <= 50
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
    WHERE cd_purchase_estimate > 1000
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        a.full_address,
        a.ca_city,
        a.ca_state,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM customer c
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
AggregatedData AS (
    SELECT 
        ci.ca_city,
        ci.ca_state,
        COUNT(ci.c_customer_sk) AS customer_count,
        COUNT(DISTINCT ci.c_email_address) AS distinct_email_count
    FROM CustomerInfo ci
    GROUP BY ci.ca_city, ci.ca_state
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ag.customer_count,
    ag.distinct_email_count
FROM FilteredAddresses ad
LEFT JOIN AggregatedData ag ON ad.ca_city = ag.ca_city AND ad.ca_state = ag.ca_state
ORDER BY ad.ca_city, ad.ca_state, ag.customer_count DESC;
