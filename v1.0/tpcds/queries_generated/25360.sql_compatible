
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), CustomerDetails AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), DateDetails AS (
    SELECT 
        d_date_sk,
        d_date,
        d_day_name,
        d_month_seq,
        d_year
    FROM 
        date_dim
    WHERE 
        d_year >= 2020
), SalesSummary AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    d.d_date,
    d.d_day_name,
    d.d_year,
    ad.full_address,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ss.total_sales,
    ss.order_count
FROM 
    DateDetails d
JOIN 
    SalesSummary ss ON d.d_date_sk = ss.ws_ship_date_sk
JOIN 
    AddressDetails ad ON ad.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = ss.ws_bill_customer_sk LIMIT 1)
JOIN 
    CustomerDetails cd ON cd.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ss.total_sales > 1000
ORDER BY 
    d.d_date DESC, 
    ss.total_sales DESC;
