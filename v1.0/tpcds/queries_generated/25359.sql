
WITH AddressComponents AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressComponents ca ON c.c_current_addr_sk = ca.ca_address_id
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
),
TopCustomers AS (
    SELECT 
        ci.full_name,
        ci.c_email_address,
        sd.total_sales,
        sd.total_orders
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_id = sd.web_site_id
    ORDER BY 
        sd.total_sales DESC
    LIMIT 10
)
SELECT 
    full_name,
    c_email_address,
    total_sales,
    total_orders,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    TopCustomers;
