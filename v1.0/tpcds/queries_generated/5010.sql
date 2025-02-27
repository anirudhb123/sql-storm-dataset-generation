
WITH total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_net_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        COALESCE(ts.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(ts.total_net_sales, 0) AS total_net_sales
    FROM 
        item
    LEFT JOIN 
        total_sales ts ON item.i_item_sk = ts.ws_item_sk
    ORDER BY 
        total_net_sales DESC
    LIMIT 10
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    SUM(ws.ws_quantity) AS quantity_purchased,
    SUM(ws.ws_net_paid) AS total_spent
FROM 
    top_items ti
JOIN 
    web_sales ws ON ti.i_item_sk = ws.ws_item_sk
JOIN 
    customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
GROUP BY 
    ti.i_item_id,
    ti.i_product_name,
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status
ORDER BY 
    total_spent DESC;
