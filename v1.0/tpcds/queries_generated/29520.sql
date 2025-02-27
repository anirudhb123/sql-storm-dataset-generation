
WITH AddressConcatenation AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', ca_suite_number) END, ''), 
               ', ', ca_city, ', ', ca_state, ' ', ca_zip, ' - ', ca_country) AS full_address
    FROM customer_address
),
DemographicProfile AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, ' - ', 
               CASE WHEN cd_marital_status = 'M' THEN 'Married' ELSE 'Single' END, ' - ',
               cd_education_status) AS demographic_info
    FROM customer_demographics
),
DateDetails AS (
    SELECT 
        d_date_sk,
        CONCAT(DATE_FORMAT(d_date, '%Y-%m-%d'), ' (', d_day_name, ')') AS formatted_date
    FROM date_dim
),
SalesInfo AS (
    SELECT 
        ws_order_number,
        CONCAT('Item ID: ', ws_item_sk, ', Quantity: ', ws_quantity, ', Total Price: $', ws_net_paid) AS sales_details
    FROM web_sales
)
SELECT 
    A.full_address, 
    D.formatted_date, 
    S.sales_details,
    DMD.demographic_info
FROM 
    AddressConcatenation A
JOIN 
    customer C ON C.c_current_addr_sk = A.ca_address_sk
JOIN 
    DemographicProfile DMD ON C.c_current_cdemo_sk = DMD.cd_demo_sk
JOIN 
    DateDetails D ON D.d_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE)
JOIN 
    SalesInfo S ON S.ws_bill_customer_sk = C.c_customer_sk
WHERE 
    A.full_address LIKE '%New York%'
ORDER BY 
    A.full_address, D.formatted_date;
