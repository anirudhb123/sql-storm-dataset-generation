
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0

    UNION ALL

    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        cs_net_profit,
        level + 1
    FROM 
        catalog_sales
    WHERE 
        cs_sales_price > 0 AND level < 5
),
Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS web_orders,
        SUM(ws_net_profit) AS total_web_profit
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON c.c_customer_sk = ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Store_Sales_By_City AS (
    SELECT
        s.s_city,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS number_of_transactions
    FROM 
        store_sales
    JOIN 
        store AS s ON s.s_store_sk = ss_store_sk
    GROUP BY 
        s.s_city
),
Sales_Analysis AS (
    SELECT 
        s.s_sales_date,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(ws_net_profit) AS total_web_profit
    FROM 
        store_sales AS ss
    FULL OUTER JOIN web_sales AS ws ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        s.s_sales_date
)
SELECT
    c.c_customer_id,
    cs.web_orders,
    cs.total_web_profit,
    s.total_sales,
    s.number_of_transactions,
    sa.total_store_profit,
    sa.total_web_profit,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.total_web_profit DESC) AS rank
FROM 
    Customer_Summary AS cs
JOIN 
    Store_Sales_By_City AS s ON cs.c_customer_sk = s.s_city
JOIN 
    Sales_Analysis AS sa ON sa.s_sales_date IS NOT NULL
WHERE 
    cs.total_web_profit > 1000
    AND s.total_sales IS NOT NULL
    AND sa.total_web_profit > 500
ORDER BY 
    cs.total_web_profit DESC, s.total_sales ASC;
