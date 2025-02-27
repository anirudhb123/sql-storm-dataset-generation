
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS full_address
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        cd.full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    full_address,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    total_quantity,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
    LENGTH(full_name) AS name_length,
    LENGTH(full_address) AS address_length
FROM 
    CombinedData
WHERE 
    cd_gender = 'F' 
    AND cd_marital_status = 'M'
    AND total_sales > 0
ORDER BY 
    total_sales DESC
LIMIT 100;
