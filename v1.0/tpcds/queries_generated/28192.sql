
WITH AddressData AS (
    SELECT 
        ca_address_id, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
DateData AS (
    SELECT 
        d_date_id,
        d_date,
        d_month_seq,
        d_year
    FROM 
        date_dim
    WHERE 
        d_month_seq BETWEEN 1 AND 12
),
SalesData AS (
    SELECT 
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_bill_customer_sk,
        ws_ship_date_sk
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    dd.d_date,
    SUM(sd.ws_sales_price) AS total_sales,
    COUNT(sd.ws_order_number) AS order_count
FROM 
    CustomerData cd
JOIN 
    AddressData ad ON cd.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_current_addr_sk = ad.ca_address_sk)
JOIN 
    DateData dd ON dd.d_date_id = (SELECT d_date_id FROM date_dim WHERE d_year = 2023)
JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
GROUP BY 
    cd.full_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ad.full_address, ad.ca_city, ad.ca_state, dd.d_date
ORDER BY 
    total_sales DESC
LIMIT 100;
