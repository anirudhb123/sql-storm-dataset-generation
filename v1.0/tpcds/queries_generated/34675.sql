
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 90
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_orders,
        itm.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rank
    FROM 
        sales_data sd
    JOIN 
        item itm ON sd.ws_item_sk = itm.i_item_sk
    WHERE 
        sd.sales_rank < 10
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        (SELECT COUNT(DISTINCT ws_order_number) 
         FROM web_sales 
         WHERE ws_bill_customer_sk = c.c_customer_sk) AS order_count,
        COALESCE(MAX(CASE WHEN cd.cd_gender = 'F' THEN cd.cd_purchase_estimate END), 0) AS female_purchase_estimate,
        COALESCE(MAX(CASE WHEN cd.cd_gender = 'M' THEN cd.cd_purchase_estimate END), 0) AS male_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    cs.c_customer_id,
    cs.order_count,
    COALESCE(ts.total_sales, 0) AS item_total_sales,
    COALESCE(ts.total_orders, 0) AS item_total_orders,
    cs.female_purchase_estimate,
    cs.male_purchase_estimate
FROM 
    customer_summary cs
LEFT JOIN 
    top_sales ts ON cs.order_count >= (SELECT AVG(order_count) FROM customer_summary)
ORDER BY 
    item_total_sales DESC, 
    cs.c_customer_id;
