
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_sales_price) AS Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS Sales_Rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
),
Customer_Details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT ss.ss_ticket_number) AS Total_Store_Sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
Item_Sales AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_sales_price) AS Total_Web_Sales,
        COUNT(ws.ws_order_number) AS Total_Orders
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    ISNULL(ISNULL(ss.Total_Store_Sales, 0), 0) AS Store_Sales,
    COALESCE(isales.Total_Web_Sales, 0) AS Web_Sales,
    sc.Total_Sales,
    sc.Sales_Rank
FROM 
    Customer_Details cd
FULL OUTER JOIN 
    Sales_CTE sc ON cd.c_customer_sk = sc.ws_item_sk
FULL OUTER JOIN 
    Item_Sales isales ON cd.c_customer_sk = isales.i_item_sk
WHERE 
    (cd.cd_gender = 'F' OR cd.cd_gender IS NULL) 
    AND (Store_Sales > 0 OR Web_Sales > 0)
ORDER BY 
    cd.c_last_name,
    cd.c_first_name;
