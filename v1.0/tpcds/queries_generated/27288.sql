
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
),
DateRange AS (
    SELECT 
        d.d_date_sk,
        d.d_date
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
FinalBenchmark AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        si.total_quantity,
        si.total_sales,
        dr.d_date
    FROM 
        CustomerInfo ci
    JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
    JOIN 
        DateRange dr ON si.ws_ship_date_sk = dr.d_date_sk
)
SELECT 
    ca.ca_country AS Country,
    COUNT(DISTINCT ci.c_customer_sk) AS Total_Customers,
    SUM(si.total_quantity) AS Total_Quantity_Sold,
    SUM(si.total_sales) AS Total_Sales_Amount,
    AVG(si.total_sales) AS Average_Sales_Per_Customer
FROM 
    FinalBenchmark fb
JOIN 
    customer_address ca ON fb.ca_state = ca.ca_state
GROUP BY 
    ca.ca_country
ORDER BY 
    Total_Sales_Amount DESC;
