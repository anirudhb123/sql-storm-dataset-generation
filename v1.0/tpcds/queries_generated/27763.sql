
WITH CustomerAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_country,
        ca_location_type
    FROM 
        customer_address
), 
DemographicInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_birth_year IS NULL THEN 'Unknown'
            ELSE CAST((YEAR(CURDATE()) - cd_birth_year) AS CHAR)
        END AS age,
        cd_credit_rating
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
JoinData AS (
    SELECT 
        c.c_customer_sk,
        ca.full_address,
        di.cd_gender,
        di.cd_marital_status,
        di.age,
        di.cd_purchase_estimate,
        sd.total_sales
    FROM 
        customer c
    JOIN 
        CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        DemographicInfo di ON c.c_current_cdemo_sk = di.cd_demo_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_address,
    cd_gender,
    cd_marital_status,
    age,
    COALESCE(total_sales, 0) AS total_sales
FROM 
    JoinData
WHERE 
    (cd_gender = 'M' AND cd_marital_status = 'M') OR 
    (cd_gender = 'F' AND cd_marital_status = 'S')
ORDER BY 
    total_sales DESC
LIMIT 100;
