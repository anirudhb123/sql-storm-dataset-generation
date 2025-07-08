
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(ca_address_sk) AS address_count,
        LISTAGG(ca_street_name, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS street_names,
        LISTAGG(DISTINCT ca_city, ', ') WITHIN GROUP (ORDER BY ca_city) AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        LISTAGG(DISTINCT c_first_name || ' ' || c_last_name, '; ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS customer_names,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    A.ca_state,
    A.address_count,
    A.street_names,
    A.unique_cities,
    C.cd_gender,
    C.customer_count,
    C.customer_names,
    C.max_purchase_estimate
FROM 
    AddressStats A
JOIN 
    CustomerStats C ON A.address_count > 0
ORDER BY 
    A.address_count DESC, C.customer_count DESC;
