
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicsInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        a.full_address,
        a.ca_zip,
        a.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        s.total_orders,
        s.total_sales
    FROM 
        AddressInfo a
    JOIN 
        DemographicsInfo d ON a.ca_state = d.cd_marketing_state
    LEFT JOIN 
        SalesInfo s ON s.ws_bill_customer_sk = d.cd_demo_sk
)
SELECT 
    ca_state,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    MAX(total_orders) AS max_orders,
    MIN(total_orders) AS min_orders,
    STRING_AGG(DISTINCT cd_marital_status) AS marital_statuses,
    STRING_AGG(DISTINCT cd_gender) AS genders
FROM 
    CombinedInfo
WHERE 
    cd_purchase_estimate > 5000
GROUP BY 
    ca_state
ORDER BY 
    customer_count DESC;
