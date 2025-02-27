
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hc.hd_dep_count,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics AS hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        inventory AS inv ON inv.inv_item_sk = (SELECT i.i_item_sk FROM item AS i WHERE i.i_item_id = (
            SELECT wp.wp_web_page_id FROM web_page AS wp WHERE wp.wp_customer_sk = c.c_customer_sk LIMIT 1
        )) AND inv.inv_warehouse_sk = (SELECT w.w_warehouse_sk FROM warehouse AS w ORDER BY RANDOM() LIMIT 1)
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, hd.hd_dep_count
),
ranked_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        customer_data
)
SELECT 
    customer_rank,
    c_customer_id,
    c_first_name,
    c_last_name,
    cd_gender,
    cd_marital_status,
    hd_income_band_sk,
    hd_dep_count,
    total_orders,
    total_spent
FROM 
    ranked_customers
WHERE 
    customer_rank <= 100
ORDER BY 
    total_spent DESC, c_customer_id
LIMIT 50;
