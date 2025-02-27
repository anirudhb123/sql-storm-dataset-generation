
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_ship_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        store_sales
    JOIN 
        item ON item.i_item_sk = store_sales.ss_item_sk
    GROUP BY 
        item.i_item_sk, item.i_item_id, item.i_product_name
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    ss.ws_ship_date_sk,
    ss.total_quantity,
    ss.total_profit,
    ti.i_item_id,
    ti.i_product_name,
    ti.total_sales
FROM 
    customer_stats AS cs
JOIN 
    sales_summary AS ss ON cs.c_customer_sk = ss.ws_ship_customer_sk
JOIN 
    top_items AS ti ON ss.ws_item_sk = ti.i_item_sk
WHERE 
    cs.rank_by_purchase <= 10 AND 
    (cs.cd_credit_rating IS NULL OR cs.cd_credit_rating = 'Excellent')
ORDER BY 
    ss.total_profit DESC, cs.c_last_name ASC;
