
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank_by_purchase <= 10
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        SUBSTRING(c.full_name, 1, 20) AS short_name,
        CONCAT(SUBSTRING(c.full_name, 1, 10), '...') AS truncated_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    fa.full_name,
    fa.cd_gender,
    fa.cd_marital_status,
    fa.cd_education_status,
    ca.ca_city,
    ca.ca_state,
    REPLACE(fa.cd_education_status, ' ', '-') AS education_status_hyphenated,
    LENGTH(fa.cd_education_status) AS education_length,
    TRIM(ca.truncated_name) AS display_name
FROM 
    FilteredCustomers fa
JOIN 
    CustomerAddresses ca ON fa.full_name LIKE CONCAT('%', ca.short_name, '%')
ORDER BY 
    fa.cd_purchase_estimate DESC,
    ca.ca_city ASC;
