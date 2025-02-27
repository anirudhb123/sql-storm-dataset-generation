
WITH total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ts.total_quantity,
        ts.total_revenue
    FROM 
        total_sales ts
    JOIN 
        item i ON ts.ws_item_sk = i.i_item_sk
    ORDER BY 
        ts.total_revenue DESC
    LIMIT 10
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 500
),
sales_with_info AS (
    SELECT 
        w.ws_order_number,
        w.ws_quantity,
        w.ws_net_paid,
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name
    FROM 
        web_sales w
    JOIN 
        customer_info ci ON w.ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = ci.c_customer_id)
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    SUM(swi.ws_quantity) AS total_quantity_sold,
    SUM(swi.ws_net_paid) AS total_revenue_generated,
    COUNT(DISTINCT swi.c_customer_id) AS unique_customers
FROM 
    top_items ti
JOIN 
    sales_with_info swi ON ti.ws_item_sk = swi.ws_item_sk
GROUP BY 
    ti.i_item_id, ti.i_item_desc
ORDER BY 
    total_revenue_generated DESC;
