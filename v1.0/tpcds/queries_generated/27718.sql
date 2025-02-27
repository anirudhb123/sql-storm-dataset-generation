
WITH AddressDetails AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(TRIM(ca.ca_street_number), ' ', TRIM(ca.ca_street_name), ' ', TRIM(ca.ca_street_type), 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca.ca_suite_number)) ELSE '' END) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
SalesSummary AS (
    SELECT 
        d.d_date AS sales_date,
        SUM(sd.total_quantity_sold) AS total_quantity,
        SUM(sd.total_sales) AS total_sales_value
    FROM 
        SalesData sd
    JOIN 
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
),
Result AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ss.sales_date,
        ss.total_quantity,
        ss.total_sales_value
    FROM 
        CustomerDetails cd
    JOIN 
        SalesSummary ss ON cd.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_sold_date_sk IN (SELECT ws_sold_date_sk FROM web_sales))
)
SELECT 
    full_name, 
    cd_gender, 
    cd_marital_status, 
    cd_purchase_estimate, 
    COUNT(total_quantity) AS number_of_purchases,
    SUM(total_sales_value) AS total_spent
FROM 
    Result
GROUP BY 
    full_name, 
    cd_gender, 
    cd_marital_status, 
    cd_purchase_estimate
ORDER BY 
    total_spent DESC
LIMIT 100;
