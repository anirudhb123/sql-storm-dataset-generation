
WITH address_summary AS (
    SELECT 
        a.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        LISTAGG(DISTINCT a.ca_city, ', ') WITHIN GROUP (ORDER BY a.ca_city) AS cities,
        LISTAGG(DISTINCT a.ca_state, ', ') WITHIN GROUP (ORDER BY a.ca_state) AS states
    FROM 
        customer_address a
    JOIN 
        customer c ON a.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        a.ca_country
),
demographics_summary AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS demographic_count
    FROM 
        customer_demographics d
    JOIN 
        customer c ON d.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        d.cd_gender, d.cd_marital_status
)
SELECT 
    a.ca_country,
    a.customer_count,
    a.cities,
    a.states,
    d.cd_gender,
    d.cd_marital_status,
    d.demographic_count
FROM 
    address_summary a
JOIN 
    demographics_summary d ON a.customer_count > d.demographic_count
ORDER BY 
    a.ca_country, d.cd_gender, d.cd_marital_status;
