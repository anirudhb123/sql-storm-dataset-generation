
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address, 
        cd.cd_gender, 
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregatedData AS (
    SELECT 
        a.ca_address_sk, 
        a.full_address, 
        a.ca_city, 
        a.ca_state, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count, 
        LISTAGG(DISTINCT c.full_name, ', ') WITHIN GROUP (ORDER BY c.full_name) AS customer_names
    FROM 
        AddressDetails a
    LEFT JOIN 
        CustomerDetails c ON c.c_customer_sk = a.ca_address_sk
    GROUP BY 
        a.ca_address_sk, a.full_address, a.ca_city, a.ca_state
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.customer_count,
    ad.customer_names,
    CASE 
        WHEN ad.customer_count > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS address_status
FROM 
    AggregatedData ad
WHERE 
    ad.ca_state = 'CA'
ORDER BY 
    ad.customer_count DESC, ad.ca_city, ad.full_address;
