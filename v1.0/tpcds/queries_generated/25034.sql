
WITH AddressInfo AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_address_sk
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
        cd.cd_purchase_estimate,
        A.full_address,
        A.ca_city,
        A.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressInfo A ON c.c_current_addr_sk = A.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
)
SELECT 
    C.full_name,
    C.cd_gender,
    C.cd_marital_status,
    C.cd_education_status,
    C.cd_purchase_estimate,
    C.full_address,
    C.ca_city,
    C.ca_state,
    SUM(S.ws_quantity) AS total_web_quantity,
    SUM(S.ws_ext_sales_price) AS total_web_sales,
    SUM(S.cs_quantity) AS total_catalog_quantity,
    SUM(S.cs_ext_sales_price) AS total_catalog_sales
FROM 
    CustomerDetails C
LEFT JOIN 
    SalesData S ON C.c_customer_id = S.ws_order_number OR C.c_customer_id = S.cs_order_number
GROUP BY 
    C.full_name, C.cd_gender, C.cd_marital_status, C.cd_education_status, C.cd_purchase_estimate, 
    C.full_address, C.ca_city, C.ca_state
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC
LIMIT 50;
