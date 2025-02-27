
WITH AddressData AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerData AS (
    SELECT 
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressData a ON c.c_current_addr_sk = a.ca_address_sk
),
DateData AS (
    SELECT 
        d_date,
        d_year,
        d_month_seq,
        d_week_seq
    FROM date_dim
    WHERE d_year >= 2020
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.full_address,
        cd.ca_city,
        cd.ca_state,
        cd.ca_zip,
        sd.total_sales,
        dd.d_year,
        dd.d_month_seq
    FROM CustomerData cd
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    CROSS JOIN DateData dd
)
SELECT 
    c_first_name,
    c_last_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    total_sales,
    d_year,
    d_month_seq,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales < 1000 THEN 'Low Sales'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Average Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM CombinedData
ORDER BY d_year, d_month_seq, total_sales DESC;
