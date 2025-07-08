
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        UPPER(ca_street_name) AS street_name_upper,
        TRIM(ca_street_type) AS street_type_trimmed,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
DemographicsData AS (
    SELECT 
        cd_demo_sk,
        COUNT(*) AS total_customers,
        LISTAGG(CASE WHEN cd_gender = 'M' THEN 'Male' WHEN cd_gender = 'F' THEN 'Female' ELSE 'Other' END, ', ') WITHIN GROUP (ORDER BY cd_gender) AS genders,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk
),
JoiningData AS (
    SELECT 
        ad.ca_address_sk,
        ad.street_name_upper,
        ad.street_type_trimmed,
        ad.full_address,
        dm.total_customers,
        dm.genders,
        dm.average_purchase_estimate
    FROM 
        AddressData ad
    JOIN 
        DemographicsData dm ON ad.ca_address_sk = dm.cd_demo_sk
)
SELECT 
    jd.full_address,
    jd.total_customers,
    jd.genders,
    jd.average_purchase_estimate,
    LENGTH(jd.street_name_upper) AS street_name_length,
    CHAR_LENGTH(jd.street_type_trimmed) AS street_type_length
FROM 
    JoiningData jd
WHERE 
    jd.average_purchase_estimate > 5000
ORDER BY 
    jd.total_customers DESC;
