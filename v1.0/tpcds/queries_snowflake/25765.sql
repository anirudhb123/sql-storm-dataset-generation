
WITH Address_City AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        LISTAGG(ca_street_name || ' ' || ca_street_number, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS street_details
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographic_Info AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demo_count,
        LISTAGG(CASE 
                     WHEN cd_marital_status = 'M' THEN 'Married'
                     WHEN cd_marital_status = 'S' THEN 'Single'
                     ELSE 'Other' 
                 END, ', ') WITHIN GROUP (ORDER BY cd_marital_status) AS marital_status_summary
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_city,
    a.address_count,
    a.street_details,
    d.cd_gender,
    d.demo_count,
    d.marital_status_summary
FROM 
    Address_City a
JOIN 
    Demographic_Info d ON a.address_count > 20
ORDER BY 
    a.address_count DESC, d.demo_count DESC;
