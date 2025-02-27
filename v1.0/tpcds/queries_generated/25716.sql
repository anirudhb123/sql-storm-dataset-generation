
WITH RegexMatches AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_address_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        REGEXP_SUBSTR(ca.ca_street_name, '[A-Z][a-z]+') AS Extracted_Street_Words
    FROM 
        customer_address AS ca
    WHERE 
        REGEXP_LIKE(ca.ca_street_name, '^[A-Z][a-z]+')
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        rm.Extracted_Street_Words
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        RegexMatches AS rm ON c.c_current_addr_sk = rm.ca_address_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_customer_id,
    COUNT(DISTINCT ci.Extracted_Street_Words) AS Unique_Street_Word_Count,
    AVG(cd.cd_purchase_estimate) AS Avg_Purchase_Estimate,
    GROUP_CONCAT(DISTINCT ci.Extracted_Street_Words ORDER BY ci.Extracted_Street_Words) AS Street_Word_List
FROM 
    CustomerInfo AS ci
JOIN 
    customer_demographics AS cd ON ci.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    ci.c_customer_sk, ci.c_customer_id
HAVING 
    COUNT(DISTINCT ci.Extracted_Street_Words) > 2;
