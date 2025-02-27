
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT d.d_date_sk 
                               FROM date_dim d 
                               WHERE d.d_date = '2023-10-01') 
      AND ws.ws_net_profit IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
      AND cd.cd_purchase_estimate > 5000
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        i.i_item_sk, i.i_item_desc
    HAVING 
        SUM(ws.ws_quantity) > 1000
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.purchase_rank,
    ti.i_item_desc,
    ti.total_quantity,
    rs.ws_net_profit
FROM 
    customer_info ci
JOIN 
    store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
JOIN 
    top_items ti ON ss.ss_item_sk = ti.i_item_sk
LEFT JOIN 
    ranked_sales rs ON ti.i_item_sk = rs.ws_item_sk
WHERE 
    rs.rank_profit = 1
  AND 
    ci.purchase_rank <= 10
ORDER BY 
    ti.total_quantity DESC, 
    ci.c_last_name ASC;
