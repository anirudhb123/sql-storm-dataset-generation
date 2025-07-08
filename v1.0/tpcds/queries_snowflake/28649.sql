
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count,
        LISTAGG(DISTINCT ca_city, ', ') WITHIN GROUP (ORDER BY ca_city) AS unique_cities,
        LISTAGG(DISTINCT ca_street_name || ' ' || ca_street_number, '; ') WITHIN GROUP (ORDER BY ca_street_name, ca_street_number) AS unique_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state
), CustomerStats AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(DISTINCT cd_education_status, ', ') WITHIN GROUP (ORDER BY cd_education_status) AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), ReturnStats AS (
    SELECT 
        sr_returned_date_sk, 
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
)
SELECT 
    a.ca_state,
    a.address_count,
    a.unique_cities,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    c.education_levels,
    r.return_count,
    r.total_return_amount
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON c.customer_count > 100
JOIN 
    ReturnStats r ON r.return_count > 50
WHERE 
    a.address_count > 50
ORDER BY 
    a.ca_state, c.cd_gender;
