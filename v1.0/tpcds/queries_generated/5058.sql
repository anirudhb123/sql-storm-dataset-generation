
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        r.c_customer_id, 
        r.c_first_name, 
        r.c_last_name, 
        r.cd_gender, 
        r.cd_marital_status, 
        r.cd_education_status, 
        r.cd_purchase_estimate
    FROM 
        ranked_customers r
    WHERE 
        r.purchase_rank <= 5
)
SELECT 
    t.c_customer_id, 
    t.c_first_name, 
    t.c_last_name, 
    t.cd_gender, 
    t.cd_marital_status, 
    t.cd_purchase_estimate,
    i.i_item_id, 
    i.i_item_desc, 
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_paid) AS total_net_paid
FROM 
    top_customers t
JOIN 
    web_sales ws ON t.c_customer_id = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
GROUP BY 
    t.c_customer_id, 
    t.c_first_name, 
    t.c_last_name, 
    t.cd_gender, 
    t.cd_marital_status, 
    t.cd_purchase_estimate, 
    i.i_item_id, 
    i.i_item_desc
ORDER BY 
    total_net_paid DESC, 
    total_quantity_sold DESC;
