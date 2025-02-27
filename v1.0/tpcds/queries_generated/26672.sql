
WITH AddressDetails AS (
    SELECT 
        ca.city AS Address_City,
        ca.state AS Address_State,
        ca.zip AS Address_Zip
    FROM customer_address ca
    WHERE ca.city IS NOT NULL
),
CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS Customer_Name,
        cd.cd_gender AS Customer_Gender,
        cd.cd_marital_status AS Marital_Status,
        cd.cd_education_status AS Education_Status,
        SUBSTR(c.c_email_address, INSTR(c.c_email_address, '@') + 1) AS Email_Domain
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS Total_Sales,
        SUM(ws_ext_discount_amt) AS Total_Discounts,
        COUNT(ws_order_number) AS Total_Orders,
        CASE 
            WHEN SUM(ws_sales_price) > 1000 THEN 'High Value'
            WHEN SUM(ws_sales_price) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS Customer_Value
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.Customer_Name,
    ci.Customer_Gender,
    ci.Marital_Status,
    ci.Education_Status,
    ad.Address_City,
    ad.Address_State,
    ad.Address_Zip,
    ss.Total_Sales,
    ss.Total_Discounts,
    ss.Total_Orders,
    ss.Customer_Value
FROM CustomerInfo ci
JOIN SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
JOIN customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
JOIN AddressDetails ad ON ad.Address_City = ca.city AND ad.Address_State = ca.state
WHERE ci.Customer_Gender = 'F' 
ORDER BY ss.Total_Sales DESC, ci.Customer_Name;
