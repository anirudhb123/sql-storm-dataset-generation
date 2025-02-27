
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(REPLACE(REPLACE(REPLACE(ca_city, ' ', ''), ',', ''), '.', '')) AS cleaned_city
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregateData AS (
    SELECT 
        ad.cleaned_city,
        COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
        COUNT(CASE WHEN cd.cd_gender = 'M' THEN 1 END) AS male_count,
        COUNT(CASE WHEN cd.cd_gender = 'F' THEN 1 END) AS female_count
    FROM 
        AddressData ad
    JOIN 
        CustomerData cd ON ad.ca_address_sk = cd.c_current_addr_sk
    GROUP BY 
        ad.cleaned_city
)
SELECT 
    cleaned_city,
    customer_count,
    average_purchase_estimate,
    male_count,
    female_count,
    CASE 
        WHEN customer_count > 100 THEN 'High'
        WHEN customer_count BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS customer_segment
FROM 
    AggregateData
ORDER BY 
    customer_count DESC;
