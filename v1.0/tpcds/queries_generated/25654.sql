
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address
    FROM 
        customer_address
),
GenderCount AS (
    SELECT 
        cd_gender,
        COUNT(*) AS count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DemographicIncome AS (
    SELECT 
        ib_income_band_sk,
        CONCAT(CAST(ib_lower_bound AS VARCHAR), ' - ', CAST(ib_upper_bound AS VARCHAR)) AS income_range
    FROM 
        income_band
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    A.ca_address_sk,
    A.full_address,
    G.cd_gender,
    G.count AS gender_count,
    D.income_range,
    COALESCE(S.total_sales, 0) AS total_sales
FROM 
    AddressParts A
JOIN 
    GenderCount G ON A.ca_address_sk IN (SELECT ca_address_sk FROM customer WHERE c_current_addr_sk = A.ca_address_sk)
JOIN 
    DemographicIncome D ON D.ib_income_band_sk = (SELECT hd_income_band_sk FROM household_demographics WHERE hd_demo_sk IN (SELECT c_current_hdemo_sk FROM customer WHERE c_current_addr_sk = A.ca_address_sk))
LEFT JOIN 
    SalesData S ON S.ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = A.ca_address_sk)
WHERE 
    A.full_address IS NOT NULL
ORDER BY 
    A.full_address;
