
WITH AddressComponents AS (
    SELECT 
        c.c_customer_sk,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, COALESCE(ca.ca_suite_number, '')) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregatedData AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS customer_count,
        STRING_AGG(full_address, '; ') AS condensed_addresses
    FROM 
        AddressComponents
    GROUP BY 
        cd_gender, cd_marital_status
),
FilteredData AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        customer_count,
        condensed_addresses
    FROM 
        AggregatedData
    WHERE 
        customer_count > 10
)
SELECT 
    fd.cd_gender,
    fd.cd_marital_status,
    fd.customer_count,
    LEFT(fd.condensed_addresses, 1000) AS truncated_addresses
FROM 
    FilteredData fd
ORDER BY 
    fd.customer_count DESC;
