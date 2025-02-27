
WITH 
    SalesData AS (
        SELECT 
            d.d_year, 
            SUM(ws_ext_sales_price) AS Total_Sales,
            COUNT(DISTINCT ws_order_number) AS Order_Count,
            SUM(ws_ext_discount_amt) AS Total_Discount,
            SUM(ws_ext_ship_cost) AS Total_Shipping,
            AVG(ws_net_profit) AS Avg_Profit
        FROM 
            web_sales s 
            JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
        WHERE 
            d.d_year BETWEEN 2020 AND 2023
        GROUP BY 
            d.d_year
    ),
    CustomerData AS (
        SELECT 
            cd.cd_gender, 
            COUNT(DISTINCT c.c_customer_sk) AS Customer_Count,
            SUM(CASE WHEN cd.cd_marital_status = 'U' THEN 1 ELSE 0 END) AS Single_Customers,
            SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS Married_Customers
        FROM 
            customer c 
            JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        GROUP BY 
            cd.cd_gender
    )
SELECT 
    sd.d_year,
    sd.Total_Sales,
    sd.Order_Count,
    sd.Total_Discount,
    sd.Total_Shipping,
    sd.Avg_Profit,
    cd.cd_gender,
    cd.Customer_Count,
    cd.Single_Customers,
    cd.Married_Customers
FROM 
    SalesData sd
JOIN 
    CustomerData cd ON sd.d_year = cd.cd_gender
ORDER BY 
    sd.d_year, cd.cd_gender;
