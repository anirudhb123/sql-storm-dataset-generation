
WITH RankedAddresses AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name, 
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_county) AS address_rank
    FROM 
        customer_address
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
),
FilteredAddresses AS (
    SELECT 
        c_customer_sk, 
        full_name, 
        full_address 
    FROM 
        RankedAddresses
    WHERE 
        address_rank <= 3
),
DemoSummary AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_sk) AS customer_count, 
        STRING_AGG(full_name, ', ') AS customer_names
    FROM 
        customer_demographics
    JOIN 
        FilteredAddresses ON c_customer_sk = c_customer_sk
    GROUP BY 
        cd_gender
)
SELECT 
    cd_gender, 
    customer_count, 
    LENGTH(customer_names) AS names_length, 
    customer_names
FROM 
    DemoSummary
ORDER BY 
    customer_count DESC;
