
WITH AddressSummary AS (
    SELECT 
        ca_city,
        CONCAT(
            ca_street_number, ' ', 
            ca_street_name, ' ', 
            ca_street_type, ' ', 
            CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT('Suite ', ca_suite_number) ELSE '' END
        ) AS FullAddress,
        LISTAGG(CONCAT(ca_zip, ' ', ca_country), ', ') WITHIN GROUP (ORDER BY ca_zip) AS ZipCountryList
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_street_number, ca_street_name, ca_street_type, ca_suite_number
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        LISTAGG(CASE 
            WHEN cd_credit_rating = 'High' THEN 'Elite'
            WHEN cd_credit_rating = 'Medium' THEN 'Standard'
            ELSE 'Budget'
        END, ', ') WITHIN GROUP (ORDER BY cd_credit_rating) AS CreditRatingCategory
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    a.ca_city, 
    a.FullAddress, 
    a.ZipCountryList, 
    d.cd_gender, 
    d.cd_marital_status, 
    d.CreditRatingCategory
FROM 
    AddressSummary a
JOIN 
    DemographicSummary d ON a.ca_city ILIKE '%City%' 
ORDER BY 
    a.ca_city, d.cd_gender;
