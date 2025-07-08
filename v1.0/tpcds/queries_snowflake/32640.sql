
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
High_Value_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_net_profit,
        CASE 
            WHEN cs.total_net_profit > 1000 THEN 'High'
            WHEN cs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS customer_value
    FROM 
        Customer_Sales cs
),
Top_Sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS top_rank
    FROM 
        Sales_CTE s
    JOIN 
        web_site ws ON s.ws_item_sk = ws.web_site_sk
    WHERE 
        ws.web_open_date_sk IS NOT NULL
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    h.customer_value,
    COALESCE(ts.total_sales, 0) AS total_item_sales,
    hs.total_net_profit
FROM 
    customer c
LEFT JOIN 
    High_Value_Customers h ON c.c_customer_sk = h.c_customer_sk
LEFT JOIN 
    Top_Sales ts ON ts.ws_item_sk = (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_ship_customer_sk = c.c_customer_sk 
        ORDER BY 
            ws_sales_price DESC 
        LIMIT 1
    )
LEFT JOIN 
    Customer_Sales hs ON hs.c_customer_sk = c.c_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
ORDER BY 
    hs.total_net_profit DESC, 
    c.c_last_name ASC;
