
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        LENGTH(COALESCE(c.c_email_address, '')) AS email_length,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInformation AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales_price,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_sold_date_sk,
        ws.ws_item_sk
),
StringBenchmark AS (
    SELECT
        cd.c_customer_sk,
        cd.full_name,
        cd.cd_gender,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        SUBSTR(cd.full_name, 1, 10) AS name_substring,
        REPLACE(cd.ca_zip, '-', '') AS zip_no_dash,
        REGEXP_REPLACE(cd.ca_city, '[^A-Za-z]', '') AS clean_city_name,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status_desc,
        JSON_OBJECT('city', cd.ca_city, 'state', cd.ca_state) AS location_json
    FROM 
        CustomerDetails AS cd
)
SELECT 
    sb.c_customer_sk,
    sb.full_name,
    sb.cd_gender,
    sb.marital_status_desc,
    sb.zip_no_dash,
    sb.clean_city_name,
    sb.location_json,
    COALESCE(si.total_sales_price, 0) AS total_sales,
    COALESCE(si.total_quantity, 0) AS total_quantity
FROM 
    StringBenchmark AS sb
LEFT JOIN 
    SalesInformation AS si ON sb.c_customer_sk = si.ws_item_sk
ORDER BY 
    sb.full_name ASC, si.total_sales DESC;
