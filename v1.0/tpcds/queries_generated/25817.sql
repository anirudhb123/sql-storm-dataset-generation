
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    cd.full_customer_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    sd.total_quantity_sold,
    sd.total_sales_amount
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = ad.ca_address_sk)
JOIN 
    SalesDetails sd ON cd.c_customer_sk = (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_item_desc LIKE '%Sample%'))
WHERE 
    cd.cd_gender = 'F' AND 
    ad.ca_state = 'CA'
ORDER BY 
    total_sales_amount DESC;
