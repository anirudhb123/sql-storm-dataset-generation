
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS Unique_Address_Count,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS Address_List
    FROM 
        customer_address
    GROUP BY 
        ca_city, 
        ca_state
), 
CustomerStatistics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS Avg_Purchase_Estimate,
        COUNT(c.c_customer_sk) AS Customer_Count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
SalesData AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS Total_Sales,
        COUNT(DISTINCT ws_order_number) AS Order_Count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.Unique_Address_Count,
    ad.Address_List,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.Avg_Purchase_Estimate,
    cs.Customer_Count,
    sd.d_year,
    sd.Total_Sales,
    sd.Order_Count
FROM 
    AddressDetails ad
JOIN 
    CustomerStatistics cs ON ad.ca_state = 'NY'  -- Focusing on New York for customers and addresses
JOIN 
    SalesData sd ON sd.d_year BETWEEN 2020 AND 2023  -- Sales from the last few years
ORDER BY 
    ad.ca_city, 
    sd.d_year DESC;
