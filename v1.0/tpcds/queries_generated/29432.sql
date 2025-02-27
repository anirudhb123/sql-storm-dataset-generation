
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LEAST(COALESCE(LENGTH(ca_street_number), 0), COALESCE(LENGTH(ca_street_name), 0), COALESCE(LENGTH(ca_street_type), 0)) AS min_length,
        GREATEST(COALESCE(LENGTH(ca_street_number), 0), COALESCE(LENGTH(ca_street_name), 0), COALESCE(LENGTH(ca_street_type), 0)) AS max_length
    FROM 
        customer_address
), CustomerGender AS (
    SELECT 
        cd_demo_sk,
        COUNT(c_customer_sk) AS customer_count,
        cd_gender
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender
), AddressStats AS (
    SELECT 
        full_address,
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        MIN(min_length) AS min_address_length,
        MAX(max_length) AS max_address_length
    FROM 
        AddressDetails
    GROUP BY 
        full_address, ca_city, ca_state
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.min_address_length,
    a.max_address_length,
    g.cd_gender,
    g.customer_count
FROM 
    AddressStats a
LEFT JOIN 
    CustomerGender g ON g.cd_demo_sk = (SELECT cd_demo_sk FROM customer WHERE c_current_addr_sk = a.ca_address_sk LIMIT 1)
ORDER BY 
    a.address_count DESC, a.min_address_length ASC;
