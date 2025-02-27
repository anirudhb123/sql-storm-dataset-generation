
WITH address_info AS (
    SELECT 
        ca.city AS Address_City,
        ca.state AS Address_State,
        CONCAT(c.first_name, ' ', c.last_name) AS Customer_Name,
        cd.gender AS Customer_Gender,
        cd.education_status AS Education_Status,
        ca.country AS Address_Country,
        ca.zip AS Address_Zip,
        ROW_NUMBER() OVER (PARTITION BY ca.city ORDER BY c.first_name) AS City_Rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
filtered_addresses AS (
    SELECT 
        Address_City,
        Address_State,
        Customer_Name,
        Customer_Gender,
        Education_Status,
        Address_Country,
        Address_Zip
    FROM 
        address_info
    WHERE 
        City_Rank <= 10 AND Address_State IN ('CA', 'NY')
),
summary AS (
    SELECT 
        Address_City,
        COUNT(*) AS Total_Customers,
        STRING_AGG(Customer_Name, ', ') AS Customer_Names,
        STRING_AGG(DISTINCT Education_Status, ', ') AS Unique_Education_Statuses,
        COUNT(DISTINCT Address_Zip) AS Unique_Zip_Codes
    FROM 
        filtered_addresses
    GROUP BY 
        Address_City
)
SELECT 
    Address_City,
    Total_Customers,
    Customer_Names,
    Unique_Education_Statuses,
    Unique_Zip_Codes
FROM 
    summary
ORDER BY 
    Total_Customers DESC;
