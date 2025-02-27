
WITH Address_City AS (
    SELECT 
        ca_addr_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
Customer_Full_Name AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
Sales_Summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cf.full_name,
    ac.full_address,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.cd_purchase_estimate,
    d.cd_credit_rating,
    ss.total_quantity,
    ss.total_sales
FROM 
    Customer_Full_Name cf
JOIN 
    Address_City ac ON cf.c_customer_sk = ac.ca_addr_sk
JOIN 
    Demographics d ON cf.c_customer_sk = d.cd_demo_sk
LEFT JOIN 
    Sales_Summary ss ON cf.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    d.cd_marital_status = 'M' 
AND 
    d.cd_gender = 'F' 
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
