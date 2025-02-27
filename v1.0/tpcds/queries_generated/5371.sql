
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),

category_sales AS (
    SELECT 
        i.i_category,
        SUM(ws.ws_net_profit) AS category_profit,
        COUNT(ws.ws_order_number) AS category_orders
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_category
),

sales_summary AS (
    SELECT 
        c.c_customer_id,
        cs.total_profit,
        cs.total_orders,
        cc.category_profit,
        cc.category_orders
    FROM 
        customer_sales cs
    JOIN 
        category_sales cc ON cs.total_profit > cc.category_profit
)

SELECT 
    s.c_customer_id,
    c.cd_gender,
    c.cd_marital_status,
    s.total_profit,
    s.total_orders,
    s.category_profit,
    s.category_orders,
    ROW_NUMBER() OVER (PARTITION BY cs.total_profit ORDER BY s.category_profit DESC) AS rank
FROM 
    sales_summary s
JOIN 
    customer_demographics c ON s.c_customer_id = c.cd_gender
WHERE 
    s.total_orders > 10
ORDER BY 
    s.total_profit DESC, s.category_profit DESC;
