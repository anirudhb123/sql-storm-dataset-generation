
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_gmt_offset
    FROM customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM customer 
    INNER JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
RankedSales AS (
    SELECT 
        sd.ws_bill_customer_sk,
        sd.total_sales,
        sd.total_orders,
        DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
)
SELECT 
    cd.full_name,
    cd.c_email_address,
    ad.full_address,
    sd.total_sales,
    sd.total_orders,
    sd.sales_rank,
    (CASE 
        WHEN cd.gender = 'M' THEN 'Mr. ' 
        WHEN cd.gender = 'F' THEN 'Ms. ' 
        ELSE 'Mx. ' 
     END) AS gender_prefix,
    ad.ca_gmt_offset
FROM RankedSales sd
JOIN CustomerData cd ON sd.ws_bill_customer_sk = cd.c_customer_sk
JOIN AddressData ad ON cd.c_current_addr_sk = ad.ca_address_sk
WHERE sd.sales_rank <= 100 
ORDER BY sales_rank;
