
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
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
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
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
RankedCustomers AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        cd.total_sales,
        cd.order_count,
        cd.avg_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ci.ca_state ORDER BY cd.total_sales DESC) AS rank
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData cd ON ci.c_customer_sk = cd.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    order_count,
    avg_net_paid,
    rank
FROM 
    RankedCustomers
WHERE 
    rank <= 5
ORDER BY 
    ca_state, rank;
