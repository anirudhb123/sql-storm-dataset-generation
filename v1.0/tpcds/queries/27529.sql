
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
AddressStats AS (
    SELECT 
        ca.ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(c.full_name, ', ') AS customer_names
    FROM 
        CustomerInfo c
    JOIN 
        customer_address ca ON c.c_customer_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
),
DemographicsSummary AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_gender
)
SELECT 
    addr.ca_state,
    addr.total_addresses,
    addr.customer_names,
    demo.cd_gender,
    demo.customer_count,
    demo.avg_purchase_estimate
FROM 
    AddressStats addr
JOIN 
    DemographicsSummary demo ON addr.total_addresses > 10 AND addr.total_addresses < 100
ORDER BY 
    addr.total_addresses DESC, demo.customer_count DESC;
