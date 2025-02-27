
WITH Processed_Customer_Info AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(c.c_email_address, '@', '[at]') AS modified_email,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_first_name
            WHEN cd.cd_gender = 'F' THEN 'Ms. ' || c.c_first_name
            ELSE c.c_first_name 
        END AS salutation,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Address_Analysis AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        LENGTH(ca.ca_street_name) AS street_name_length,
        SUBSTR(ca.ca_zip, 1, 5) AS zip_prefix
    FROM 
        customer_address ca
),
Combined_Data AS (
    SELECT 
        pci.full_name,
        pci.modified_email,
        pci.salutation,
        aa.ca_city,
        aa.street_name_length,
        aa.zip_prefix
    FROM 
        Processed_Customer_Info pci
    JOIN 
        Address_Analysis aa ON pci.c_customer_id = (SELECT ca.ca_address_id FROM customer_address ca WHERE ca.ca_address_id = pci.c_customer_id LIMIT 1)
)
SELECT 
    full_name,
    modified_email,
    salutation,
    ca_city,
    AVG(street_name_length) AS avg_street_name_length,
    COUNT(DISTINCT zip_prefix) AS unique_zip_prefixes
FROM 
    Combined_Data
GROUP BY 
    full_name, modified_email, salutation, ca_city
ORDER BY 
    avg_street_name_length DESC;
