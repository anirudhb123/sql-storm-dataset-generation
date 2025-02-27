
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregatedResults AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
        MAX(cd.cd_marital_status) AS predominant_marital_status,
        STRING_AGG(DISTINCT cd.cd_gender, ', ') AS genders
    FROM 
        AddressDetails ad
    JOIN 
        CustomerDetails cd ON cd.c_customer_sk IN (
            SELECT DISTINCT c.c_customer_sk 
            FROM customer c 
            WHERE c.c_current_addr_sk = ad.ca_address_sk
        )
    GROUP BY 
        ad.full_address, ad.ca_city, ad.ca_state, ad.ca_zip
)
SELECT 
    AR.full_address,
    AR.ca_city,
    AR.ca_state,
    AR.ca_zip,
    AR.customer_count,
    AR.predominant_marital_status,
    AR.genders
FROM 
    AggregatedResults AR
WHERE 
    AR.customer_count > 5 AND 
    AR.ca_state = 'CA'
ORDER BY 
    AR.customer_count DESC;
