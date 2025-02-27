
WITH AddressInfo AS (
    SELECT 
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_zip
    FROM 
        customer_address
), CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), CombinedData AS (
    SELECT 
        ci.full_name,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ss.total_sales,
        ss.order_count,
        ci.cd_gender,
        ci.cd_marital_status
    FROM 
        CustomerInfo ci
    JOIN 
        AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    JOIN 
        SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)

SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    total_sales,
    order_count,
    cd_gender,
    cd_marital_status
FROM 
    CombinedData
WHERE 
    total_sales > 1000 AND 
    cd_gender = 'F'
ORDER BY 
    total_sales DESC, 
    full_name;
