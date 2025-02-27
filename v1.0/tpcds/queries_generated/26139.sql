
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               COALESCE(CONCAT(' Suite ', TRIM(ca_suite_number)), ''), 
               ', ', TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip)) AS full_address
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        LOWER(TRIM(cd_education_status)) AS education_status,
        CASE 
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_band
    FROM 
        customer_demographics
),
DateDimensions AS (
    SELECT 
        d_date_sk,
        TO_CHAR(d_date, 'YYYY-MM-DD') AS formatted_date,
        EXTRACT(MONTH FROM d_date) AS month,
        EXTRACT(YEAR FROM d_date) AS year,
        MAX(d_dom) OVER (PARTITION BY EXTRACT(YEAR FROM d_date)) AS max_dom_year
    FROM 
        date_dim
),
FinalBenchmark AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.formatted_date,
        d.month,
        d.year,
        cd.education_status,
        cd.purchase_estimate_band
    FROM 
        customer c
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        DateDimensions d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        cd_gender = 'F' 
        AND cd_marital_status = 'M' 
        AND d.month = 12
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(d.month) AS average_month,
    STRING_AGG(DISTINCT education_status, ', ') AS distinct_education_statuses
FROM 
    FinalBenchmark
GROUP BY 
    d.year;
