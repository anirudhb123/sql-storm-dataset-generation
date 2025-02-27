WITH AddressAnalysis AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(ca_gmt_offset) AS average_gmt_offset,
        STRING_AGG(ca_street_name, ', ') AS all_street_names,
        STRING_AGG(ca_street_type, ', ') AS all_street_types
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city
),
CustomerDemographicsAnalysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimated,
        COUNT(DISTINCT cd_demo_sk) AS unique_demographics
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
DateAnalysis AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(DISTINCT d_date_id) AS unique_dates,
        STRING_AGG(d_day_name, ', ') AS all_day_names
    FROM 
        date_dim
    GROUP BY 
        d_year, d_month_seq
)
SELECT 
    a.ca_state,
    a.ca_city,
    a.unique_addresses,
    a.average_gmt_offset,
    a.all_street_names,
    a.all_street_types,
    c.cd_gender,
    c.cd_marital_status,
    c.total_purchase_estimated,
    c.unique_demographics,
    d.d_year,
    d.d_month_seq,
    d.unique_dates,
    d.all_day_names
FROM 
    AddressAnalysis a
JOIN 
    CustomerDemographicsAnalysis c ON a.ca_state = 'CA'  
JOIN 
    DateAnalysis d ON d.d_year > 1998  
ORDER BY 
    a.ca_city, c.cd_gender, d.d_year DESC;