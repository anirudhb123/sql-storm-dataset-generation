
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        ris.ws_item_sk,
        ris.total_quantity,
        ris.total_net_profit
    FROM 
        ranked_sales ris
    WHERE 
        ris.rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    ti.total_quantity,
    ti.total_net_profit,
    c.cd_gender,
    c.cd_marital_status
FROM 
    top_items ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
JOIN 
    web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    ti.total_net_profit DESC, ti.total_quantity DESC;
