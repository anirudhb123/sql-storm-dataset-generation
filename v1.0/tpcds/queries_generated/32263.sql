
WITH RECURSIVE sales_summary AS (
    SELECT 
        s_store_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        s_store_sk, ws_sold_date_sk

    UNION ALL

    SELECT 
        s_store_sk,
        DATEADD(day, 1, ws_sold_date_sk) AS ws_sold_date_sk,
        total_quantity,
        total_sales
    FROM 
        sales_summary
    WHERE 
        ws_sold_date_sk < CURRENT_DATE
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_credit_rating IS NOT NULL
),
inventory_status AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_date_sk, inv_item_sk
),
date_range AS (
    SELECT 
        d_date_sk,
        d_date
    FROM 
        date_dim
    WHERE 
        d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_credit_rating,
    ss.total_quantity,
    ss.total_sales,
    COALESCE(inv.total_inventory, 0) AS remaining_inventory,
    dr.d_date
FROM 
    customer_info ci
JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.s_store_sk
LEFT JOIN 
    inventory_status inv ON ss.ws_sold_date_sk = inv.inv_date_sk AND ss.s_store_sk = inv.inv_item_sk
JOIN 
    date_range dr ON ss.ws_sold_date_sk = dr.d_date_sk
WHERE 
    ci.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC, 
    ci.c_last_name, 
    ci.c_first_name;
