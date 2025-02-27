
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    cd.cd_gender,
    cd.cd_marital_status,
    sd.total_spent,
    sd.order_count,
    sd.avg_order_value,
    ad.full_address
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY 
    total_spent DESC
LIMIT 100;
