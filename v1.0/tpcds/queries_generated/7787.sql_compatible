
WITH top_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
), customer_details AS (
    SELECT 
        cu.c_customer_sk,
        cu.c_first_name,
        cu.c_last_name,
        cu.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count
    FROM 
        top_customers cu
    JOIN 
        customer_demographics cd ON cu.c_customer_sk = cd.cd_demo_sk
), item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        is.total_sold,
        is.total_profit
    FROM 
        item i
    JOIN 
        item_sales is ON i.i_item_sk = is.ws_item_sk
    ORDER BY 
        is.total_profit DESC
    LIMIT 5
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_dep_count,
    ti.i_product_name,
    ti.total_sold,
    ti.total_profit
FROM 
    customer_details cd
CROSS JOIN 
    top_items ti
ORDER BY 
    cd.c_last_name, cd.c_first_name;
