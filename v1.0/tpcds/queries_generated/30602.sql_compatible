
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        ws_sales_price, 
        ws_sold_date_sk, 
        1 AS Sale_Level,
        ws_order_number
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL

    SELECT 
        cs_item_sk, 
        cs_sales_price, 
        cs_sold_date_sk, 
        Sale_Level + 1,
        cs_order_number
    FROM 
        catalog_sales
    WHERE 
        cs_item_sk IN (SELECT ws_item_sk FROM Sales_CTE)
),
Aggregate_Sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS Total_Web_Sales,
        COUNT(DISTINCT ws_order_number) AS Order_Count,
        MAX(Sale_Level) AS Max_Sale_Level
    FROM 
        Sales_CTE
    GROUP BY 
        ws_item_sk
),
Item_Details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        CASE 
            WHEN i_current_price < 20 THEN 'Low'
            WHEN i_current_price BETWEEN 20 AND 100 THEN 'Medium'
            ELSE 'High'
        END AS Price_Category
    FROM 
        item
    WHERE 
        i_rec_end_date IS NULL
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.i_current_price,
    id.Price_Category,
    COALESCE(as.Total_Web_Sales, 0) AS Total_Web_Sales,
    COALESCE(as.Order_Count, 0) AS Order_Count,
    CASE 
        WHEN as.Max_Sale_Level IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS Sales_Status
FROM 
    Item_Details id
LEFT JOIN 
    Aggregate_Sales as ON id.i_item_sk = as.ws_item_sk
WHERE 
    id.Price_Category = 'Low'
ORDER BY 
    Total_Web_Sales DESC;
