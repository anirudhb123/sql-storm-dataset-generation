
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
total_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_item_sk
),
frequent_items AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        COUNT(ws.ws_order_number) > 10
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_profit,
    ti.total_sales_price,
    fi.order_count
FROM 
    ranked_customers rc
JOIN 
    total_sales ti ON rc.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ti.ws_item_sk LIMIT 1)
JOIN 
    frequent_items fi ON ti.ws_item_sk = fi.ws_item_sk
WHERE 
    rc.profit_rank <= 5
ORDER BY 
    rc.total_profit DESC;
