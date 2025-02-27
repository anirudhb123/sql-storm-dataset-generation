
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(SUBSTRING(ca_street_name, 1, 30)) AS short_street_name,
        UPPER(SUBSTRING(ca_street_type, 1, 15)) AS street_type_upper,
        CONCAT(TRIM(ca_city), ', ', TRIM(ca_state)) AS city_state,
        REPLACE(REPLACE(ca_zip, '-', ''), ' ', '') AS clean_zip
    FROM 
        customer_address
), CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender_desc,
        FORMAT(c.c_birth_month, '00') + '/' + FORMAT(c.c_birth_day, '00') + '/' + CAST(c.c_birth_year AS VARCHAR) AS date_of_birth,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), RankedAddresses AS (
    SELECT 
        a.ca_address_sk,
        a.short_street_name,
        a.street_type_upper,
        a.city_state,
        a.clean_zip,
        ROW_NUMBER() OVER (PARTITION BY a.city_state ORDER BY a.ca_address_sk) AS address_rank
    FROM 
        AddressParts a
)
SELECT 
    cd.full_name,
    cd.gender_desc,
    cd.date_of_birth,
    ra.short_street_name,
    ra.street_type_upper,
    ra.city_state,
    ra.clean_zip
FROM 
    CustomerDetails cd
JOIN 
    RankedAddresses ra ON cd.c_customer_sk = ra.ca_address_sk
WHERE 
    cd.purchase_rank <= 100
ORDER BY 
    cd.purchase_rank, ra.city_state;
