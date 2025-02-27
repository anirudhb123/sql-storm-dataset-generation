
WITH Address_City AS (
    SELECT DISTINCT ca.city AS AddressCity
    FROM customer_address ca
),
Customer_Demographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    FROM customer_demographics cd
    WHERE cd.cd_gender IN ('M', 'F')
),
Potential_Customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ac.AddressCity
    FROM customer c
    JOIN Customer_Demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN Address_City ac ON c.c_current_addr_sk = ac.AddressCity
),
Sales_by_Customer AS (
    SELECT ws.bill_customer_sk, SUM(ws.ws_sales_price) AS TotalSales
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
),
Customer_Summary AS (
    SELECT pc.c_first_name, pc.c_last_name, pc.c_email_address, pc.cd_gender, cs.TotalSales
    FROM Potential_Customers pc
    LEFT JOIN Sales_by_Customer cs ON pc.c_customer_sk = cs.bill_customer_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS FullName, 
    c.c_email_address,
    CASE 
        WHEN c.cd_gender = 'M' THEN 'Male'
        WHEN c.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS Gender, 
    COALESCE(cs.TotalSales, 0) AS TotalSales
FROM Customer_Summary cs
JOIN Potential_Customers c ON cs.c_email_address = c.c_email_address
WHERE cs.TotalSales > 1000
ORDER BY TotalSales DESC;
