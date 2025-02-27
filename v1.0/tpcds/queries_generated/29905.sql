
WITH AddressAnalysis AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM customer_address
),
DemographicsAnalysis AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        UPPER(cd_credit_rating) AS credit_rating_upper,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        CONCAT(cd_gender, ' ', cd_marital_status) AS gender_marital
    FROM customer_demographics
),
DateAnalysis AS (
    SELECT 
        d_date_sk,
        TO_CHAR(d_date, 'Month YYYY') AS formatted_date,
        EXTRACT(DOW FROM d_date) AS day_of_week,
        d_month_seq,
        d_quarter_seq,
        d_year,
        CASE 
            WHEN d_holiday = 'Y' THEN 'Holiday'
            ELSE 'Regular Day'
        END AS day_type
    FROM date_dim
)
SELECT 
    AA.full_address,
    DA.gender_marital,
    DA.credit_rating_upper,
    DA.cd_purchase_estimate,
    DA.cd_dep_count,
    DA.cd_dep_employed_count,
    DA.cd_dep_college_count,
    DA.day_type,
    DA.formatted_date,
    COUNT(DISTINCT Appointments.appointment_id) AS total_appointments,
    AVG(Appointments.appointment_duration) AS avg_appointment_duration
FROM AddressAnalysis AS AA
JOIN DemographicsAnalysis AS DA ON DA.cd_demo_sk = AA.ca_address_sk 
JOIN DateAnalysis AS DA ON DA.d_date_sk = AA.ca_address_sk 
LEFT JOIN (
    SELECT 
        appointment_id,
        customer_sk,
        duration AS appointment_duration
    FROM appointments
) AS Appointments ON Appointments.customer_sk = DA.cd_demo_sk
GROUP BY 
    AA.full_address, 
    DA.gender_marital, 
    DA.credit_rating_upper, 
    DA.cd_purchase_estimate, 
    DA.cd_dep_count, 
    DA.cd_dep_employed_count, 
    DA.cd_dep_college_count, 
    DA.day_type, 
    DA.formatted_date
ORDER BY 
    AA.full_address ASC, 
    DA.cd_purchase_estimate DESC;
