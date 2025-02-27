
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458988 AND 2459311  -- Example date range
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_ext_sales_price,
        cs_net_profit,
        sd.level + 1
    FROM 
        catalog_sales cs
    JOIN 
        sales_data sd ON cs.cs_item_sk = sd.ws_item_sk AND cs.cs_order_number = sd.ws_order_number
),
summarized_sales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_ext_sales_price) AS total_sales,
        SUM(s.ws_net_profit) AS total_profit,
        COUNT(s.ws_order_number) AS order_count
    FROM 
        web_sales s
    GROUP BY 
        s.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.total_orders,
    ci.total_spent,
    ss.total_quantity,
    ss.total_sales,
    ss.total_profit
FROM 
    customer_info ci
JOIN 
    summarized_sales ss ON ci.c_customer_sk = ss.ws_item_sk
WHERE 
    ci.total_spent > 500 AND  -- Filter for significant spenders
    ss.total_sales IS NOT NULL
ORDER BY 
    ci.total_spent DESC
LIMIT 10
;
