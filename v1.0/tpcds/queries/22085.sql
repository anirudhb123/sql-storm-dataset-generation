
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= DATE '2002-10-01' 
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > DATE '2002-10-01')
    GROUP BY 
        ws.ws_item_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(sd.total_profit, 0)) AS total_spent
    FROM 
        customer_data c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        sales_data sd ON ws.ws_item_sk = sd.ws_item_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(COALESCE(sd.total_profit, 0)) > 
        (SELECT AVG(total_spent) FROM (SELECT SUM(ws.ws_net_profit) AS total_spent 
                                         FROM web_sales ws 
                                         GROUP BY ws.ws_bill_customer_sk) AS avg_spent)
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS item_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
    HAVING 
        SUM(ws.ws_quantity) > 100
    ORDER BY 
        item_profit DESC
    LIMIT 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(ti.i_item_desc, 'No Purchases') AS top_item,
    hc.total_spent AS customer_spending,
    ti.total_sold AS item_sold
FROM 
    high_value_customers hc
LEFT JOIN 
    customer c ON hc.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    top_items ti ON ti.i_item_sk IN (SELECT DISTINCT ws.ws_item_sk 
                                       FROM web_sales ws 
                                       WHERE ws.ws_bill_customer_sk = hc.c_customer_sk)
ORDER BY 
    customer_spending DESC, top_item;
