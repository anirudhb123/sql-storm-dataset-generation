
WITH Address_Stats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS total_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        STRING_AGG(ca_street_name, ', ') AS all_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Customer_Demo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_purchase_estimate
),
Date_Aggregation AS (
    SELECT 
        d_year, 
        COUNT(DISTINCT d_date) AS total_days,
        STRING_AGG(d_day_name, ', ') AS weekdays_used
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.max_street_name_length,
    a.avg_street_name_length,
    SUBSTRING(a.all_street_names FROM 1 FOR 200) AS sample_street_names,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    c.education_statuses,
    d.d_year,
    d.total_days,
    d.weekdays_used
FROM 
    Address_Stats a
JOIN 
    Customer_Demo c ON a.total_addresses > 100
JOIN 
    Date_Aggregation d ON d.total_days > 250
ORDER BY 
    a.total_addresses DESC, c.cd_purchase_estimate DESC
LIMIT 100;
