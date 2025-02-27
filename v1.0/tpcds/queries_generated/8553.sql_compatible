
WITH customer_spending AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        SUM(ws.ws_quantity) AS total_items_purchased
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),

average_spending AS (
    SELECT 
        AVG(total_spent) AS avg_spent,
        AVG(total_items_purchased) AS avg_items
    FROM 
        customer_spending
),

high_value_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_spending cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    WHERE 
        cs.total_spent > (SELECT avg_spent FROM average_spending)
),

top_items AS (
    SELECT 
        i.i_item_id,
        COUNT(ws.ws_item_sk) AS purchase_count,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_revenue DESC
    LIMIT 10
)

SELECT 
    hvc.c_customer_id,
    hvc.total_spent,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    ti.i_item_id,
    ti.purchase_count,
    ti.total_revenue
FROM 
    high_value_customers hvc
JOIN 
    top_items ti ON hvc.total_items_purchased > 0
ORDER BY 
    hvc.total_spent DESC, ti.total_revenue DESC;
