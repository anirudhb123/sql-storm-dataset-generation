
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        ca.address_id as address_id
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_id
),
SalesAggregation AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) as total_sales,
        COUNT(ws_order_number) as order_count,
        MAX(ws_sold_date_sk) as last_purchase_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.gender,
    cd.marital_status,
    cd.education_status,
    COALESCE(sa.total_sales, 0) AS total_sales,
    COALESCE(sa.order_count, 0) AS order_count,
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ca.ca_country
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesAggregation sa ON cd.c_customer_id = sa.ws_bill_customer_sk
JOIN 
    AddressDetails ca ON ca.ca_address_id = cd.address_id
WHERE 
    cd.education_status LIKE '%Bachelor%' 
ORDER BY 
    total_sales DESC
LIMIT 100;
