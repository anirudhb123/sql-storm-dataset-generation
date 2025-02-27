
WITH address_similarity AS (
    SELECT 
        ca_address_sk, 
        ca_city,
        ca_state, 
        ca_country,
        LENGTH(ca_street_name) AS street_length,
        LOWER(ca_street_name) AS normalized_street_name,
        ROW_NUMBER() OVER (PARTITION BY LOWER(ca_city), LOWER(ca_state) ORDER BY LENGTH(ca_street_name) DESC) AS rank
    FROM 
        customer_address
), 
demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        UPPER(cd_credit_rating) AS credit_rating
    FROM 
        customer_demographics
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.street_length,
        a.normalized_street_name
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    ci.full_name, 
    ci.ca_city, 
    ci.ca_state, 
    ci.ca_country, 
    COUNT(DISTINCT ci.normalized_street_name) AS unique_street_names,
    AVG(ci.street_length) AS average_street_length,
    STRING_AGG(DISTINCT ci.cd_gender || ' - ' || ci.cd_marital_status, ', ') AS gender_marital_status
FROM 
    customer_info ci
JOIN 
    address_similarity AS a ON ci.ca_city = a.ca_city AND ci.ca_state = a.ca_state
WHERE 
    a.rank <= 3
GROUP BY 
    ci.full_name, 
    ci.ca_city, 
    ci.ca_state, 
    ci.ca_country
ORDER BY 
    unique_street_names DESC, 
    average_street_length DESC;
