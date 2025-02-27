
WITH AddressCounts AS (
    SELECT ca_county, 
           COUNT(*) AS address_count,
           STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_address
    FROM customer_address 
    GROUP BY ca_county
),
DemographicsSummary AS (
    SELECT cd_gender, 
           cd_marital_status, 
           COUNT(*) AS demographic_count,
           STRING_AGG(CONCAT(cd_education_status, ' (', cd_purchase_estimate, ')'), '; ') AS education_details
    FROM customer_demographics 
    GROUP BY cd_gender, cd_marital_status
),
DateSummary AS (
    SELECT d_year, 
           d_month_seq, 
           COUNT(DISTINCT d_date_sk) AS active_days,
           STRING_AGG(d_day_name, ', ') AS active_days_names
    FROM date_dim 
    GROUP BY d_year, d_month_seq
)
SELECT a.ca_county, 
       a.address_count, 
       a.full_address, 
       d.cd_gender, 
       d.cd_marital_status, 
       d.demographic_count, 
       d.education_details, 
       date_summary.d_year, 
       date_summary.d_month_seq, 
       date_summary.active_days, 
       date_summary.active_days_names 
FROM AddressCounts a
JOIN DemographicsSummary d ON a.address_count > d.demographic_count
JOIN DateSummary date_summary ON d.demographic_count > date_summary.active_days
ORDER BY a.ca_county, d.cd_gender, date_summary.d_year DESC;
