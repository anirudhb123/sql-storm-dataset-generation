
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
FilteredAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_country
    HAVING 
        COUNT(*) > 1
),
SalesDetails AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        (ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
)
SELECT 
    rc.full_name,
    fa.ca_city,
    fa.ca_state,
    fa.ca_country,
    SUM(sd.total_sales) AS total_sales_generated
FROM 
    RankedCustomers rc
JOIN 
    FilteredAddresses fa ON rc.c_customer_id = fa.ca_address_id
JOIN 
    SalesDetails sd ON rc.c_customer_id = sd.ws_bill_customer_sk
GROUP BY 
    rc.full_name, fa.ca_city, fa.ca_state, fa.ca_country
ORDER BY 
    total_sales_generated DESC
LIMIT 10;
