
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_first_name, c.c_last_name) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressComponents AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    ac.full_address,
    COALESCE(sd.total_sales, 0) AS total_sales
FROM 
    RankedCustomers rc
LEFT JOIN 
    AddressComponents ac ON rc.c_customer_sk = ac.ca_address_sk
LEFT JOIN 
    SalesData sd ON rc.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    rc.rn = 1
ORDER BY 
    rc.cd_gender, rc.c_last_name, rc.c_first_name;
