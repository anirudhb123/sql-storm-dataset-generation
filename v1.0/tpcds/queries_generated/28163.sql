
WITH Address_City_Aggregation AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names,
        COUNT(DISTINCT ca_street_number) AS unique_street_numbers
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Gender_Education_Aggregation AS (
    SELECT 
        cd_gender,
        cd_education_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_education_status
),
Date_Aggregation AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_id) AS unique_dates,
        STRING_AGG(DISTINCT d_day_name, ', ') AS days_of_week
    FROM 
        date_dim
    GROUP BY 
        d_year
),
Final_Aggregation AS (
    SELECT 
        a.ca_city,
        a.unique_addresses,
        a.street_names,
        a.unique_street_numbers,
        g.cd_gender,
        g.cd_education_status,
        g.customer_count,
        d.d_year,
        d.unique_dates,
        d.days_of_week
    FROM 
        Address_City_Aggregation a
    JOIN 
        Gender_Education_Aggregation g ON 1=1
    JOIN 
        Date_Aggregation d ON 1=1
)

SELECT 
    ca_city, 
    unique_addresses, 
    street_names, 
    unique_street_numbers, 
    cd_gender, 
    cd_education_status, 
    customer_count, 
    d_year, 
    unique_dates, 
    days_of_week
FROM 
    Final_Aggregation
ORDER BY 
    ca_city, cd_gender, d_year;
