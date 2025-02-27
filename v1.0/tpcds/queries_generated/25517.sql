
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
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
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        sd.total_sales,
        sd.total_profit
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        AddressDetails ad ON cd.c_customer_id = ad.ca_address_id
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales IS NULL THEN 'No sales' 
        WHEN total_profit > 1000 THEN 'High Profit'
        WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    FinalReport
WHERE 
    cd_gender = 'M' 
ORDER BY 
    total_sales DESC;
