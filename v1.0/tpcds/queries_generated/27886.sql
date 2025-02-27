
WITH Combined_Addresses AS (
    SELECT 
        ca_address_sk, 
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_suite_number, ca_city, ca_state, ca_zip) AS Full_Address
    FROM customer_address
),
Combined_Customers AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS Full_Name, 
        c_email_address,
        c_birth_month,
        c_birth_day,
        cd_gender
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
Recent_Web_Sales AS (
    SELECT 
        ws_bill_customer_sk, 
        COUNT(*) AS Total_Orders,
        SUM(ws_ext_sales_price) AS Total_Sales
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_date BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY) AND CURRENT_DATE
    )
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.Full_Name,
    c.c_email_address,
    a.Full_Address,
    rws.Total_Orders,
    rws.Total_Sales
FROM Combined_Customers AS c
JOIN Combined_Addresses AS a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN Recent_Web_Sales AS rws ON c.c_customer_sk = rws.ws_bill_customer_sk
WHERE c.c_birth_month IN (1, 2) -- Filtering for customers born in January or February
ORDER BY rws.Total_Sales DESC NULLS LAST
LIMIT 100;
