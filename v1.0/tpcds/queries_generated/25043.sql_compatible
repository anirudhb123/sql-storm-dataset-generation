
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_month) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IN ('M', 'S') 
        AND c.c_birth_country IS NOT NULL
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state
),
CustomerSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    rc.full_name,
    rc.c_birth_country,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    ca.ca_city,
    ca.ca_state,
    cs.total_sales,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales' 
        ELSE 'Sales Available' 
    END AS sales_status
FROM 
    RankedCustomers rc
LEFT JOIN 
    CustomerAddresses ca ON rc.c_customer_id = ca.ca_address_id
LEFT JOIN 
    CustomerSales cs ON rc.c_customer_id = cs.ws_bill_customer_sk
WHERE 
    rc.rn <= 5
ORDER BY 
    rc.cd_gender, rc.c_birth_country;
