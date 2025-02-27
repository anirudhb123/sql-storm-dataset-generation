
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        CASE 
            WHEN LENGTH(c.c_email_address) > 0 THEN 'Email Provided'
            ELSE 'No Email'
        END AS email_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_purchase_estimate > 1000
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Result AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_income_band_sk,
        ci.cd_purchase_estimate,
        ci.email_status,
        ci.full_address,
        sd.total_sales,
        sd.order_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    cd_gender,
    cd_marital_status,
    cd_income_band_sk,
    cd_purchase_estimate,
    email_status,
    full_address,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count
FROM 
    Result
ORDER BY 
    total_sales DESC
LIMIT 100;
