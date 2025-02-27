
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
AddressSummary AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(LENGTH(c.email_address) - LENGTH(REPLACE(c.email_address, '@', ''))) AS avg_email_chars
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
),
DemographicStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
        MAX(cd.cd_credit_rating) AS max_credit_rating
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_gender
)
SELECT 
    r.customers_full_name,
    r.cd_gender,
    a.ca_city,
    a.ca_state,
    d.average_purchase_estimate,
    a.customer_count,
    r.rank
FROM 
    RankedCustomers r
JOIN 
    AddressSummary a ON a.customer_count > 10
JOIN 
    DemographicStats d ON r.cd_gender = d.cd_gender
WHERE 
    r.rank <= 5
ORDER BY 
    a.ca_city, 
    a.customer_count DESC, 
    r.cd_gender;
