
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        web_sales.ws_order_number,
        web_sales.ws_item_sk,
        web_sales.ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        web_sales.ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        
    UNION ALL

    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit + Sales_CTE.ws_net_profit,
        Sales_CTE.level + 1
    FROM 
        web_sales ws
    JOIN 
        Sales_CTE ON Sales_CTE.ws_order_number = ws.ws_order_number
    WHERE 
        Sales_CTE.level < 3
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year > 1980
),
Sales_Summary AS (
    SELECT 
        si.ws_item_sk,
        SUM(si.ws_net_profit) AS total_net_profit,
        COUNT(si.ws_order_number) AS order_count
    FROM 
        web_sales si
    GROUP BY 
        si.ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    COALESCE(ssp.total_net_profit, 0) AS total_net_profit,
    COALESCE(ssp.order_count, 0) AS order_count,
    COALESCE(sc.level, 0) AS sales_level
FROM 
    Customer_Info ci
LEFT JOIN 
    Sales_Summary ssp ON ci.c_customer_sk = ssp.ws_item_sk
LEFT JOIN 
    Sales_CTE sc ON ssp.ws_item_sk = sc.ws_item_sk
WHERE 
    ci.rnk = 1
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ssp.total_net_profit, 
    ssp.order_count, 
    sc.level
ORDER BY 
    ci.c_last_name ASC,
    total_net_profit DESC
LIMIT 100;
