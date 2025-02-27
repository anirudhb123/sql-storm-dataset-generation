
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_county) AS county_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN LENGTH(ca_street_name) > 30 THEN 1 ELSE 0 END) AS long_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender, 
        COUNT(cd_demo_sk) AS total_customers, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_income_band_sk) AS income_band_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
ReturnStats AS (
    SELECT 
        s_store_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns
    GROUP BY 
        s_store_sk
)
SELECT 
    as.ca_state,
    as.county_count,
    as.avg_street_name_length,
    as.long_street_names,
    ds.cd_gender,
    ds.total_customers,
    ds.avg_purchase_estimate,
    ds.income_band_count,
    rs.total_returns,
    rs.total_return_amount,
    rs.total_return_tax
FROM 
    AddressStats as
JOIN 
    DemographicsStats ds ON as.county_count > 10
JOIN 
    ReturnStats rs ON as.county_count = rs.total_returns
ORDER BY 
    as.ca_state, ds.cd_gender;
