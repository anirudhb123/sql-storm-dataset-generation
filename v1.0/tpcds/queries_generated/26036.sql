
WITH AddressSummary AS (
    SELECT 
        ca_state, 
        COUNT(ca_address_sk) AS total_addresses,
        SUM(CASE WHEN LENGTH(ca_street_name) > 30 THEN 1 ELSE 0 END) AS long_street_names,
        AVG(LENGTH(ca_city)) AS avg_city_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(cd_demo_sk) AS total_demographics
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(c.c_email_address, '@', '[@]') AS modified_email
    FROM 
        customer c
    WHERE 
        c.c_preferred_cust_flag = 'Y'
)
SELECT 
    AS.state,
    DS.cd_gender,
    DS.cd_marital_status,
    AS.total_addresses,
    DS.total_demographics,
    AS.long_street_names,
    AS.avg_city_length,
    CD.full_name,
    CD.modified_email
FROM 
    AddressSummary AS AS
JOIN 
    DemographicSummary DS ON AS.ca_state = 'CA'
JOIN 
    CustomerDetails CD ON CD.c_customer_id IN (SELECT c_customer_id FROM customer WHERE c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = AS.ca_state))
ORDER BY 
    AS.total_addresses DESC, DS.total_demographics DESC;
