
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
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
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        dc.d_date,
        dc.d_month_seq,
        dc.d_year,
        ws.web_site_sk,
        c.c_first_name,
        c.c_last_name,
        ap.full_address
    FROM 
        web_sales ws
    JOIN 
        date_dim dc ON ws.ws_sold_date_sk = dc.d_date_sk
    JOIN 
        CustomerDetails c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        AddressParts ap ON ws.ws_bill_addr_sk = ap.ca_address_sk
)
SELECT 
    sd.year,
    COUNT(sd.ws_order_number) AS total_orders,
    SUM(sd.ws_quantity) AS total_quantity,
    ROUND(SUM(sd.ws_ext_sales_price), 2) AS total_sales,
    AVG(sd.ws_sales_price) AS avg_sales_price,
    STRING_AGG(DISTINCT sd.full_address, '; ') AS unique_addresses
FROM 
    (SELECT 
        d_year AS year,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price 
    FROM 
        SalesData) AS sd
GROUP BY 
    sd.year
ORDER BY 
    sd.year DESC 
LIMIT 10;
