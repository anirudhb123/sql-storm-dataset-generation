
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        RankedCustomers
    WHERE 
        rank <= 10
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        c.full_name
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    fi.full_name,
    fi.cd_gender,
    fi.cd_marital_status,
    fi.cd_education_status,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    LENGTH(ai.ca_city) AS city_length,
    LENGTH(fi.full_name) AS name_length,
    CONCAT(fi.cd_gender, '-', fi.cd_marital_status) AS gender_marital_status,
    REPLACE(ai.ca_city, ' ', '_') AS city_no_spaces
FROM 
    FilteredCustomers fi
JOIN 
    AddressInfo ai ON fi.full_name = ai.full_name
ORDER BY 
    fi.full_name;
