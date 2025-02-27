
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        0 AS level
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws2.ws_sold_date_sk) FROM web_sales ws2)
    
    UNION ALL
    
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        level + 1
    FROM 
        web_sales ws
    INNER JOIN Sales_CTE sc ON ws.ws_item_sk = sc.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk < sc.ws_sold_date_sk
), Total_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sc.ws_quantity, 0)) AS total_quantity,
        SUM(COALESCE(sc.ws_net_profit, 0)) AS total_net_profit,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(sc.ws_net_profit, 0)) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        Sales_CTE sc ON c.c_customer_sk = sc.ws_item_sk
    GROUP BY 
        c.c_customer_id
), Top_Customers AS (
    SELECT 
        c.*, 
        ts.total_quantity, 
        ts.total_net_profit
    FROM 
        customer c
    JOIN 
        Total_Sales ts ON c.c_customer_id = ts.c_customer_id
    WHERE 
        ts.customer_rank <= 10
)

SELECT 
    tc.c_customer_id,
    tc.total_quantity,
    tc.total_net_profit,
    COALESCE(tcd.cd_gender, 'Unknown') AS customer_gender,
    COALESCE(tcd.cd_marital_status, 'Unknown') AS marital_status
FROM 
    Top_Customers tc
LEFT JOIN 
    customer_demographics tcd ON tc.c_customer_sk = tcd.cd_demo_sk
WHERE 
    tc.total_net_profit > (SELECT AVG(total_net_profit) FROM Total_Sales)
ORDER BY 
    tc.total_net_profit DESC;
