
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_sales_price) AS total_sales_amount
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    sd.w_warehouse_id,
    sd.total_sales_quantity,
    ROUND(sd.total_sales_amount, 2) AS total_sales_amount,
    CONCAT(cd.ca_city, ', ', cd.ca_state, ' ', cd.ca_zip) AS address,
    cd.ca_country
FROM 
    CustomerDetails cd
JOIN 
    SalesData sd ON cd.c_customer_id IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_bill_customer_sk IS NOT NULL)
ORDER BY 
    sd.total_sales_amount DESC
LIMIT 100;
