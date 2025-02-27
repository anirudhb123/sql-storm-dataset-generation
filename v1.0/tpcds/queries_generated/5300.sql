
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_sales_price,
        CASE 
            WHEN ws_sales_price < 20 THEN 'Low Price'
            WHEN ws_sales_price BETWEEN 20 AND 50 THEN 'Mid Price'
            ELSE 'High Price'
        END AS Price_Category
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
AggregatedSales AS (
    SELECT 
        sd.Price_Category,
        SUM(sd.ws_quantity) AS Total_Quantity,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS Total_Sales
    FROM SalesData sd
    GROUP BY sd.Price_Category
),
CustomerInfo AS (
    SELECT 
        cd.cd_gender,
        SUM(asales.Total_Quantity) AS Gender_Quantity,
        SUM(asales.Total_Sales) AS Gender_Sales
    FROM AggregatedSales asales
    JOIN customer c ON c.c_customer_sk = asales.ws_item_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    ci.cd_gender, 
    ci.Gender_Quantity, 
    ci.Gender_Sales, 
    COALESCE((SELECT SUM(Total_Quantity) FROM CustomerInfo), 0) AS Overall_Quantity,
    COALESCE((SELECT SUM(Total_Sales) FROM CustomerInfo), 0) AS Overall_Sales
FROM CustomerInfo ci
ORDER BY ci.cd_gender;
