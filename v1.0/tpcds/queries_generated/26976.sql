
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        UPPER(SUBSTRING(ca_zip FROM 1 FOR 5)) AS formatted_zip
    FROM 
        customer_address
),
GenderedCustomers AS (
    SELECT 
        c_customer_sk,
        CONCAT(TRIM(c_salutation), ' ', TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        cd_gender,
        ca.city AS address_city,
        ca.state AS address_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    gc.full_name,
    gc.cd_gender,
    gc.address_city,
    gc.address_state,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    ROUND(AVG(LENGTH(ap.full_address)), 2) AS avg_address_length,
    MAX(ap.formatted_zip) AS latest_zip_code
FROM 
    GenderedCustomers gc
LEFT JOIN 
    SalesSummary ss ON gc.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    AddressParts ap ON gc.c_customer_sk = ap.ca_address_sk
WHERE 
    gc.cd_gender = 'F'
GROUP BY 
    gc.full_name, gc.cd_gender, gc.address_city, gc.address_state
ORDER BY 
    total_sales DESC, gc.full_name ASC;
