
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_net_profit > 0
    UNION ALL
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price * 1.05 AS ws_sales_price, 
        ws_quantity,
        (ws_net_profit * 0.9) AS ws_net_profit, 
        level + 1
    FROM 
        Sales_CTE
    WHERE 
        level < 5
),
Max_Profit AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ss.ss_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    COALESCE(sp.total_spent, 0) AS total_spent,
    COALESCE(mp.total_net_profit, 0) AS profits,
    RANK() OVER (PARTITION BY cs.cd_gender ORDER BY COALESCE(sp.total_spent, 0) DESC) AS rank
FROM 
    Customer_Summary cs
LEFT JOIN 
    Max_Profit mp ON cs.c_customer_sk = mp.ws_item_sk
LEFT JOIN 
    (SELECT 
         ws_item_sk, 
         SUM(ws_net_profit) AS total_spent 
     FROM 
         web_sales 
     GROUP BY 
         ws_item_sk) sp ON cs.c_customer_sk = sp.ws_item_sk
WHERE 
    COALESCE(mp.total_net_profit, 0) > 0 OR COALESCE(sp.total_spent, 0) IS NOT NULL
ORDER BY 
    cs.cd_gender, total_spent DESC;
