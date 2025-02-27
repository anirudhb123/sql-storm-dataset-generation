
WITH AddressInfo AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ci.full_address,
        si.total_sales,
        si.order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressInfo ci ON c.c_current_addr_sk = ci.ca_address_id
    LEFT JOIN 
        SalesInfo si ON c.c_customer_sk = si.ws_bill_customer_sk
),
FilteredCustomers AS (
    SELECT 
        *,
        CASE 
            WHEN total_sales > 1000 THEN 'High Value'
            WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        CustomerInfo
)
SELECT 
    c_first_name,
    c_last_name,
    full_address,
    cd_gender,
    cd_marital_status,
    total_sales,
    order_count,
    customer_value_category
FROM 
    FilteredCustomers
WHERE 
    ca_state = 'CA'
ORDER BY 
    total_sales DESC;
