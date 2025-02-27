
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL

    UNION ALL

    SELECT 
        cs_item_sk, 
        cs_order_number, 
        cs_net_profit,
        level + 1
    FROM 
        catalog_sales
    WHERE 
        cs_item_sk IN (SELECT ws_item_sk FROM web_sales)
        AND level < 3
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Web_Orders,
        SUM(ws.ws_net_profit) AS Total_Web_Profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
Sales_Performance AS (
    SELECT 
        si.ws_item_sk,
        COUNT(si.ws_order_number) AS Total_Sales,
        SUM(si.ws_net_profit) AS Total_Profit,
        MAX(si.ws_net_profit) AS Max_Profit_Per_Order,
        AVG(si.ws_net_profit) AS Avg_Profit_Per_Order
    FROM 
        web_sales si
    GROUP BY 
        si.ws_item_sk
),
Combined_Data AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        coalesce(sp.Total_Sales, 0) AS Total_Online_Sales,
        coalesce(sp.Total_Profit, 0) AS Total_Online_Profit,
        SUM(CASE WHEN sp.Max_Profit_Per_Order IS NULL THEN 0 ELSE sp.Max_Profit_Per_Order END) * 100 AS Max_Profit_Per_Item
    FROM 
        Customer_Info ci
    LEFT JOIN 
        Sales_Performance sp ON ci.c_customer_sk = sp.ws_item_sk
    GROUP BY 
        ci.c_first_name, ci.c_last_name, ci.cd_gender
)
SELECT 
    *,
    CASE WHEN cd_gender = 'M' THEN 'Male'
         WHEN cd_gender = 'F' THEN 'Female'
         ELSE 'Other' END AS Gender_Description,
    ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY Total_Online_Profit DESC) AS Profit_Rank
FROM 
    Combined_Data
WHERE 
    Total_Online_Profit > 0
ORDER BY 
    Total_Online_Profit DESC, Profit_Rank
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
