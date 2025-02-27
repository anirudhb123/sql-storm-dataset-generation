
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        c.cs_item_sk, 
        SUM(c.cs_quantity) AS total_quantity, 
        SUM(c.cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales c
    JOIN 
        Sales_CTE s ON c.cs_item_sk = s.ws_item_sk
    GROUP BY 
        c.cs_item_sk
),
Customer_Sales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(s.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk
),
Item_Stats AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        CASE 
            WHEN COALESCE(s.total_net_profit, 0) > 1000 THEN 'High Value'
            WHEN COALESCE(s.total_net_profit, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        item i
    LEFT JOIN 
        Sales_CTE s ON i.i_item_sk = s.ws_item_sk
),
Aggregate_Stats AS (
    SELECT 
        value_category, 
        COUNT(i.i_item_sk) AS item_count, 
        SUM(i.total_net_profit) AS total_revenue
    FROM 
        Item_Stats i
    GROUP BY 
        value_category
)
SELECT 
    a.value_category, 
    a.item_count, 
    a.total_revenue, 
    (SELECT AVG(total_net_profit) FROM Customer_Sales) AS avg_customer_profit
FROM 
    Aggregate_Stats a
ORDER BY 
    total_revenue DESC;
