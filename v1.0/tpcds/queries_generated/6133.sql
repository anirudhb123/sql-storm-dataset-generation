
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        COUNT(DISTINCT ws.item_sk) AS unique_items_sold,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
        AND ws.sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.bill_customer_sk
),
top_customers AS (
    SELECT 
        b.bill_customer_sk,
        b.total_profit,
        b.total_orders,
        b.unique_items_sold
    FROM 
        ranked_sales b
    WHERE 
        b.rank <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_profit,
    tc.total_orders,
    tc.unique_items_sold,
    SUM(ws.quantity) AS total_quantity_sold
FROM 
    top_customers tc
JOIN 
    customer c ON tc.bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
GROUP BY 
    c.c_first_name, c.c_last_name, tc.total_profit, tc.total_orders, tc.unique_items_sold
ORDER BY 
    tc.total_profit DESC;
