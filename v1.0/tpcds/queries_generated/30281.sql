
WITH RECURSIVE item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451502 AND 2451503
    GROUP BY 
        ws.ws_item_sk
),
top_selling_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        is.total_quantity,
        is.total_profit
    FROM 
        item AS i
    JOIN 
        item_sales AS is ON i.i_item_sk = is.ws_item_sk
    WHERE 
        is.profit_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as gender_rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
sales_channel AS (
    SELECT 
        'Web' AS channel,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_item_sk
    UNION ALL
    SELECT 
        'Store' AS channel,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales AS ss
    GROUP BY 
        ss.ss_item_sk
),
final_sales AS (
    SELECT 
        si.i_item_id,
        si.i_item_desc,
        COALESCE(ws.total_quantity, 0) + COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ws.total_profit, 0) + COALESCE(ss.total_profit, 0) AS total_profit
    FROM 
        top_selling_items AS si
    LEFT JOIN 
        sales_channel AS ws ON si.i_item_sk = ws.ws_item_sk AND ws.channel = 'Web'
    LEFT JOIN 
        sales_channel AS ss ON si.i_item_sk = ss.ss_item_sk AND ss.channel = 'Store'
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.total_quantity,
    f.total_profit,
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ci.cd_dep_count
FROM 
    final_sales AS f
JOIN 
    customer_info AS ci ON ci.gender_rank <= 5
WHERE 
    f.total_profit > 5000
ORDER BY 
    f.total_profit DESC;
