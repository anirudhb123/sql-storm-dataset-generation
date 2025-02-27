
WITH AddressSegments AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS FullAddress
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
DemographicSegments AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COALESCE(cd_marital_status, 'Unknown') AS marital_status,
        COALESCE(cd_education_status, 'Not Specified') AS education_status
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 0
),
DateSegments AS (
    SELECT 
        d_date_sk,
        TO_CHAR(d_date, 'YYYY-MM-DD') AS formatted_date,
        CASE 
            WHEN d_dow IN (6, 0) THEN 'Weekend'
            ELSE 'Weekday'
        END AS DayType
    FROM 
        date_dim
),
CustomerSegments AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS FullCustomerName,
        ca.FullAddress,
        dd.formatted_date,
        dd.DayType,
        cd.cd_gender,
        cd.marital_status,
        cd.education_status
    FROM 
        customer c
    JOIN 
        AddressSegments ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        DateSegments dd ON c.c_first_shipto_date_sk = dd.d_date_sk
    JOIN 
        DemographicSegments cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    FullCustomerName,
    FullAddress,
    formatted_date,
    DayType,
    cd_gender,
    marital_status,
    education_status,
    COUNT(*) OVER (PARTITION BY cd_gender) AS GenderCount,
    ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY formatted_date DESC) AS RankByRecentDate
FROM 
    CustomerSegments
WHERE 
    DayType = 'Weekend'
ORDER BY 
    FullCustomerName, formatted_date DESC
LIMIT 100;
