
WITH AddressInformation AS (
    SELECT 
        ca.city, 
        ca.state, 
        ca.zip,
        CONCAT(ca.street_number, ' ', ca.street_name, ' ', ca.street_type) AS full_address,
        CASE 
            WHEN ca.state IN ('NY', 'CA', 'TX') THEN 'Major State'
            ELSE 'Minor State'
        END AS state_category
    FROM 
        customer_address ca
),
CustomerInformation AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ai.full_address,
        ai.state_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressInformation ai ON c.c_current_addr_sk = ai.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.full_address,
    ci.state_category,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    CustomerInformation ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    total_sales DESC, 
    ci.c_last_name;
