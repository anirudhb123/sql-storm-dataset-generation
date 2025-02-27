
WITH AddressInfo AS (
    SELECT 
        ca_state,
        LENGTH(TRIM(ca_city)) AS city_length,
        UPPER(TRIM(ca_street_name)) AS upper_street_name,
        LOWER(TRIM(ca_street_type)) AS lower_street_type
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(*) AS total_days,
        MAX(d_date) AS max_date,
        MIN(d_date) AS min_date
    FROM 
        date_dim
    GROUP BY 
        d_year
),
SalesInfo AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ai.ca_state,
    ai.city_length,
    ci.cd_gender,
    ci.cd_marital_status,
    ds.d_year,
    ds.total_days,
    si.total_sales,
    si.order_count,
    COUNT(DISTINCT ci.full_name) AS unique_customers
FROM 
    AddressInfo ai
JOIN 
    CustomerInfo ci ON ai.ca_state IN (SELECT DISTINCT ca_state FROM customer_address)
JOIN 
    DateStats ds ON 1=1
LEFT JOIN 
    SalesInfo si ON si.ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer)
GROUP BY 
    ai.ca_state, 
    ai.city_length, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ds.d_year,
    ds.total_days,
    si.total_sales,
    si.order_count
ORDER BY 
    ai.ca_state, 
    unique_customers DESC;
