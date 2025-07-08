
WITH Address_Stats AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        AVG(ca_gmt_offset) AS average_gmt_offset,
        LISTAGG(DISTINCT ca_street_name, '; ') WITHIN GROUP (ORDER BY ca_street_name) AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographic_Stats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        LISTAGG(DISTINCT cd_marital_status, ', ') WITHIN GROUP (ORDER BY cd_marital_status) AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Combined_Stats AS (
    SELECT 
        a.ca_city,
        a.unique_addresses,
        a.average_gmt_offset,
        a.street_names,
        d.cd_gender,
        d.customer_count,
        d.total_dependents,
        d.marital_statuses
    FROM 
        Address_Stats a
    JOIN 
        Demographic_Stats d ON d.customer_count > 100
)
SELECT 
    ca_city,
    unique_addresses,
    average_gmt_offset,
    street_names,
    cd_gender,
    customer_count,
    total_dependents,
    marital_statuses
FROM 
    Combined_Stats
ORDER BY 
    total_dependents DESC, ca_city ASC;
