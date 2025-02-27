
WITH Address_Info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        CA_COUNTRY AS country_full
    FROM 
        customer_address
),
Customer_Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        REPLACE(cd_education_status, ' ', '_') AS formatted_education,
        cd_purchase_estimate,
        TRIM(cd_credit_rating) AS trimmed_credit_rating
    FROM 
        customer_demographics
),
Sales_Info AS (
    SELECT 
        ws.sold_date_sk,
        ws_bill_customer_sk,
        ws_salary
    FROM 
        web_sales ws
    JOIN 
        Item i ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_item_desc LIKE '%sneakers%' AND 
        ws.ws_sales_price > 50
),
Combined_Info AS (
    SELECT 
        ci.ca_address_sk,
        ci.full_address,
        ci.ca_city,
        ci.ca_state,
        cd.cd_gender,
        cd.formatted_education,
        si.sold_date_sk
    FROM 
        Address_Info ci
    JOIN 
        Customer_Demographics cd ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = ci.ca_address_sk)
    LEFT JOIN 
        Sales_Info si ON si.ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = ci.ca_address_sk)
)
SELECT 
    full_address,
    CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_location,
    COUNT(DISTINCT sold_date_sk) AS purchase_days,
    COUNT(DISTINCT cd_gender) AS gender_count,
    MAX(formatted_education) AS highest_education_format
FROM 
    Combined_Info
GROUP BY 
    full_address, ca_city, ca_state, ca_zip
ORDER BY 
    purchase_days DESC, full_location ASC
LIMIT 100;
