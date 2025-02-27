
WITH AddressDetails AS (
    SELECT 
        ca.city AS Address_City,
        ca.state AS Address_State,
        ca.country AS Address_Country,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS Customer_Name,
        cd.edication_status AS Customer_Education_Status
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        CASE 
            WHEN ws.ws_sales_price > 50 THEN 'High Price'
            WHEN ws.ws_sales_price BETWEEN 20 AND 50 THEN 'Medium Price'
            ELSE 'Low Price'
        END AS Price_Category,
        ws.ws_quantity AS Quantity_Sold,
        ws.ws_net_profit AS Net_Profit,
        d.d_year AS Sales_Year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregateSales AS (
    SELECT 
        sd.Price_Category,
        COUNT(*) AS Total_Sales,
        SUM(sd.Quantity_Sold) AS Total_Quantity_Sold,
        SUM(sd.Net_Profit) AS Total_Net_Profit,
        d.Address_City,
        d.Address_State,
        d.Address_Country
    FROM 
        SalesData sd
    JOIN 
        AddressDetails d ON 1=1 
    GROUP BY 
        sd.Price_Category, d.Address_City, d.Address_State, d.Address_Country
)
SELECT 
    Price_Category,
    Address_City,
    Address_State,
    Address_Country,
    Total_Sales,
    Total_Quantity_Sold,
    Total_Net_Profit
FROM 
    AggregateSales
ORDER BY 
    Total_Net_Profit DESC;
