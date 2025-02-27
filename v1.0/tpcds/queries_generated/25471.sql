
WITH AddressStats AS (
    SELECT 
        ca_state,
        CONCAT('Street: ', ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(*) AS address_count,
        MAX(ca_zip) AS max_zip,
        MIN(ca_zip) AS min_zip
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_street_number, ca_street_name, ca_street_type
),
CustomerDetails AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        a.full_address
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        AddressStats a ON c.c_current_addr_sk = a.ca_state
),
SalesSummary AS (
    SELECT 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.total_sales,
    ss.total_orders,
    ss.cd_gender,
    ss.cd_marital_status,
    ad.max_zip,
    ad.min_zip
FROM 
    SalesSummary ss
JOIN 
    AddressStats ad ON ss.cd_gender = ad.ca_state
ORDER BY 
    ss.total_sales DESC, ss.total_orders DESC;
