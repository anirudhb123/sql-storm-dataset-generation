
WITH RECURSIVE Sales_CTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, 
           ws_sales_price, ws_net_profit, 1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_quantity, 
           ws.ws_sales_price, ws.ws_net_profit, sc.level + 1
    FROM web_sales ws
    JOIN Sales_CTE sc ON ws.ws_item_sk = sc.ws_item_sk
    WHERE sc.level < 5
),
Max_Sales AS (
    SELECT ws_item_sk, SUM(ws_net_profit) AS total_profit
    FROM Sales_CTE
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_profit) > 5000
),
Customer_Sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           ms.total_profit
    FROM customer c
    JOIN Max_Sales ms ON c.c_customer_sk = (SELECT DISTINCT ws_bill_customer_sk 
                                              FROM web_sales 
                                              WHERE ws_item_sk IN (SELECT ws_item_sk FROM Max_Sales))
),
Ranked_Customers AS (
    SELECT c.c_first_name, c.c_last_name, cs.total_profit,
           RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM Customer_Sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT rc.c_first_name, rc.c_last_name, rc.total_profit
FROM Ranked_Customers rc
WHERE rc.rank <= 10
ORDER BY rc.total_profit DESC;

