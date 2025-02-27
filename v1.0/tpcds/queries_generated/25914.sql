
WITH AddressAnalysis AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length,
        LENGTH(ca_country) AS country_length
    FROM 
        customer_address
),
DemographicAnalysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
DateAnalysis AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(ws.web_order_number) AS total_sales,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year, d_month_seq
),
FinalBenchmark AS (
    SELECT 
        aa.full_address,
        aa.ca_city,
        aa.ca_state,
        aa.ca_country,
        da.cd_gender,
        da.cd_marital_status,
        da.demographic_count,
        da.avg_purchase_estimate,
        da.avg_purchase_estimate * da.demographic_count AS expected_sales,
        da.demographic_count / NULLIF(db.total_sales, 0) AS sales_effectiveness,
        db.total_sales_value
    FROM 
        AddressAnalysis aa
    JOIN 
        DemographicAnalysis da ON aa.ca_city = da.cd_gender
    JOIN 
        DateAnalysis db ON aa.ca_state = CAST(db.d_year AS CHAR(4))
)
SELECT 
    full_address, 
    ca_city, 
    ca_state, 
    ca_country, 
    cd_gender, 
    cd_marital_status, 
    demographic_count, 
    avg_purchase_estimate, 
    expected_sales, 
    sales_effectiveness, 
    total_sales_value
FROM 
    FinalBenchmark
ORDER BY 
    total_sales_value DESC
LIMIT 100;
