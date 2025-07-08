
WITH ExtendedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS Full_Street_Address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS Full_City_State_Zip,
        LOWER(ca_country) AS Normalized_Country
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        CASE 
            WHEN cd_marital_status = 'S' THEN 'Single'
            WHEN cd_marital_status = 'M' THEN 'Married'
            ELSE 'Other'
        END AS Marital_Status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
JoinedData AS (
    SELECT 
        ca.ca_address_sk,
        ca.Full_Street_Address,
        ca.Full_City_State_Zip,
        ca.Normalized_Country,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.Marital_Status,
        cd.cd_purchase_estimate
    FROM 
        ExtendedAddresses ca
    JOIN 
        CustomerDemographics cd ON ca.ca_address_sk = cd.cd_demo_sk
)
SELECT 
    COUNT(*) AS Total_Entries,
    AVG(cd_purchase_estimate) AS Average_Purchase_Estimate,
    MIN(Full_City_State_Zip) AS Lexical_Min_City_State_Zip,
    MAX(Full_City_State_Zip) AS Lexical_Max_City_State_Zip,
    LISTAGG(Full_Street_Address, '; ') AS All_Full_Street_Addresses
FROM 
    JoinedData
WHERE 
    Normalized_Country IN ('united states', 'canada')
GROUP BY 
    cd_gender, Marital_Status, Full_City_State_Zip, Full_Street_Address
ORDER BY 
    Total_Entries DESC;
