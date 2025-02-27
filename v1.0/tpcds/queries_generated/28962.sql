
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_age_group,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.full_address,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    cd.ca_state = 'CA'
ORDER BY 
    total_sales DESC, cd.full_name;
