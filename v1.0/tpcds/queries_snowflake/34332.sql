
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim) 
    UNION ALL
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        sd.level + 1
    FROM 
        web_sales ws
    JOIN 
        sales_data sd ON ws.ws_order_number = sd.ws_order_number
    WHERE 
        sd.level < 5
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE 
            WHEN SUM(ws.ws_quantity) > 100 THEN 'High'
            WHEN SUM(ws.ws_quantity) BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_tier
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(sd.ws_quantity) AS total_sold,
        ROW_NUMBER() OVER (ORDER BY SUM(sd.ws_net_profit) DESC) AS rank
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.level < 3
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_profit,
    cs.purchase_tier,
    ti.i_item_desc,
    ti.total_sold,
    CASE 
        WHEN ti.total_sold IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM 
    customer_summary cs
LEFT JOIN 
    top_items ti ON cs.c_customer_sk = ti.i_item_sk
WHERE 
    cs.total_profit > 1000
ORDER BY 
    cs.total_profit DESC, ti.total_sold DESC
LIMIT 10;
