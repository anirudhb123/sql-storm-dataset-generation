
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS Total_Sales,
        COUNT(ws.ws_order_number) AS Total_Orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS Total_Quantity_Sold,
        AVG(ws.ws_sales_price) AS Avg_Sales_Price
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.Total_Sales,
        cs.Total_Orders,
        is.Total_Quantity_Sold,
        is.Avg_Sales_Price
    FROM 
        CustomerSales cs
    JOIN 
        ItemSales is ON cs.c_customer_sk IN (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = cs.c_customer_sk)
)
SELECT 
    ss.c_customer_sk,
    ss.Total_Sales,
    ss.Total_Orders,
    ss.Total_Quantity_Sold,
    ss.Avg_Sales_Price,
    CASE 
        WHEN ss.Total_Sales > 1000 THEN 'High Value'
        WHEN ss.Total_Sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS Customer_Value_Category
FROM 
    SalesSummary ss
ORDER BY 
    ss.Total_Sales DESC;
