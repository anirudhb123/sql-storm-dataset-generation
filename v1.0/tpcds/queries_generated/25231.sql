
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ' ', COALESCE(ca_suite_number, '')) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ' ', COALESCE(ca_suite_number, ''))) AS address_length
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(DISTINCT c_customer_sk) AS total_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
DateMetrics AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date) AS unique_dates,
        MAX(d_dom) AS max_dom,
        MIN(d_dom) AS min_dom
    FROM 
        date_dim
    GROUP BY 
        d_year
),
StateCityCount AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city
),
BenchmarkResults AS (
    SELECT 
        ad.ca_city,
        ad.ca_state,
        ad.full_address,
        ad.address_length,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cm.total_customers,
        dm.unique_dates,
        dm.max_dom,
        dm.min_dom,
        sc.address_count
    FROM 
        AddressDetails ad
    JOIN 
        CustomerDemographics cd ON TRUE 
    JOIN 
        DateMetrics dm ON TRUE 
    JOIN 
        StateCityCount sc ON ad.ca_city = sc.ca_city AND ad.ca_state = sc.ca_state
)
SELECT 
    ca_state,
    ca_city,
    COUNT(DISTINCT full_address) AS unique_addresses,
    AVG(address_length) AS avg_address_length,
    SUM(total_customers) AS total_customer_count
FROM 
    BenchmarkResults
GROUP BY 
    ca_state, ca_city
ORDER BY 
    total_customer_count DESC, ca_state, ca_city;
