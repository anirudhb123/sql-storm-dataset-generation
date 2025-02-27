
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS Full_Name,
        c.c_birth_month,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS Full_Address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer_address ca
),
TotalSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS Total_Sales
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        cd.c_customer_id,
        cd.Full_Name,
        ad.Full_Address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        ts.Total_Sales
    FROM CustomerDetails cd
    JOIN AddressDetails ad ON cd.c_customer_id = ad.ca_address_id
    LEFT JOIN TotalSales ts ON cd.c_customer_id = ts.ws_bill_customer_sk
)
SELECT 
    Full_Name,
    Full_Address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    COALESCE(Total_Sales, 0) AS Total_Sales_Amount
FROM CustomerSales
WHERE c_birth_month = 12
AND c_birth_year >= 1980
ORDER BY Total_Sales_Amount DESC;
