
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CONCAT(cd_gender, '-', cd_marital_status) AS demographic_group
    FROM 
        customer_demographics
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_email_address,
        CASE 
            WHEN c_birth_year < 1950 THEN 'Senior'
            WHEN c_birth_year BETWEEN 1950 AND 1980 THEN 'Middle-aged'
            ELSE 'Young'
        END AS age_group
    FROM 
        customer
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_quantity) AS total_items_sold
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
)

SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    c.c_email_address,
    CONCAT(a.ca_city, ', ', a.ca_state, ' ', a.ca_zip) AS address,
    a.address_length,
    d.demographic_group,
    CASE 
        WHEN s.total_sales > 10000 THEN 'High Value'
        WHEN s.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    CustomerDetails c
JOIN 
    AddressDetails a ON c.c_customer_sk = a.ca_address_sk
JOIN 
    DemographicDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN 
    SalesData s ON c.c_customer_sk = s.web_site_id
WHERE 
    a.address_length > 30
ORDER BY 
    customer_value DESC, address_length DESC;
