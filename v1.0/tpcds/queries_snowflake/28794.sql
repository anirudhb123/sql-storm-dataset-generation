
WITH Address_City AS (
    SELECT 
        ca_city,
        COUNT(*) AS city_count,
        LISTAGG(ca_street_name || ' ' || ca_street_type || ' ' || ca_street_number, ', ') AS streets
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demo_count,
        LISTAGG(cd_education_status || ' (' || cd_credit_rating || ')', ', ') AS education_info
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
Aggregate_Results AS (
    SELECT
        ac.ca_city,
        ac.city_count,
        ac.streets,
        d.cd_gender,
        d.cd_marital_status,
        d.demo_count,
        d.education_info
    FROM 
        Address_City ac
    JOIN 
        Demographics d ON ac.city_count > d.demo_count
)
SELECT 
    ar.ca_city,
    ar.city_count,
    ar.streets,
    ar.cd_gender,
    ar.cd_marital_status,
    ar.demo_count,
    COUNT(*) OVER (PARTITION BY ar.cd_gender) AS gender_partition_count,
    ROW_NUMBER() OVER (PARTITION BY ar.cd_gender ORDER BY ar.city_count DESC) AS rank
FROM 
    Aggregate_Results ar
WHERE 
    ar.city_count > 5
ORDER BY 
    ar.city_count DESC, ar.cd_gender;
