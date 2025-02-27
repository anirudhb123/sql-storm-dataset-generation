
WITH recent_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales,
        rs.net_profit,
        ROW_NUMBER() OVER (ORDER BY rs.net_profit DESC) AS rn
    FROM 
        item i
    JOIN 
        recent_sales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        i.i_current_price > 0
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.net_profit
FROM 
    customer_info ci
JOIN 
    top_items ti ON ci.c_customer_id IN (
        SELECT DISTINCT 
            ws.ws_bill_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_item_sk IN (SELECT ws_item_sk FROM recent_sales)
    )
WHERE 
    ti.rn <= 10
ORDER BY 
    ti.net_profit DESC;
