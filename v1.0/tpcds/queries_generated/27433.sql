
WITH CityAddress AS (
    SELECT 
        DISTINCT ca_city, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS Full_Address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating,
        ca.ca_city
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS Total_Sales,
        COUNT(ws_order_number) AS Order_Count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.c_customer_sk, 
        cd.c_first_name, 
        cd.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating, 
        ss.Total_Sales, 
        ss.Order_Count, 
        ca.ca_city
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN 
        CityAddress ca ON cd.ca_city = ca.ca_city
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    SUM(c.Total_Sales) AS Total_Sales_Sum,
    AVG(c.cd_purchase_estimate) AS Avg_Purchase_Estimate,
    COUNT(*) AS Number_Of_Customers,
    ca.Full_Address
FROM 
    CombinedData c
JOIN 
    CityAddress ca ON c.ca_city = ca.ca_city
WHERE 
    c.cd_marital_status = 'M'
GROUP BY 
    c.c_first_name, c.c_last_name, c.cd_gender, ca.Full_Address
ORDER BY 
    Total_Sales_Sum DESC
LIMIT 10;
