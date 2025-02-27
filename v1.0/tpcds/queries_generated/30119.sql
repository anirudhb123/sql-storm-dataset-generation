
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM 
        store_sales 
    GROUP BY 
        s_store_sk
),
store_info AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_city,
        s_state,
        s_country,
        COALESCE(s_tax_precentage, 0) AS tax_percentage
    FROM 
        store
),
customer_info AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer
    JOIN 
        customer_demographics 
    ON 
        customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk 
    WHERE 
        cd_credit_rating IS NOT NULL
),
inventory_summary AS (
    SELECT 
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    WHERE 
        inv_quantity_on_hand IS NOT NULL
    GROUP BY 
        inv_warehouse_sk
),
latest_web_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_web_profit
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IN (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023
        )
    GROUP BY 
        ws_item_sk
)
SELECT 
    si.s_store_name,
    si.s_city,
    si.s_state,
    si.s_country,
    sh.total_sales,
    sh.total_revenue,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    i.total_quantity,
    COALESCE(ws.total_web_profit, 0) AS total_web_profit
FROM 
    store_info si
LEFT JOIN 
    sales_hierarchy sh ON si.s_store_sk = sh.s_store_sk
LEFT JOIN 
    customer_info ci ON sh.rank <= 10
LEFT JOIN 
    inventory_summary i ON si.s_store_sk = i.inv_warehouse_sk
LEFT JOIN 
    latest_web_sales ws ON ws.ws_item_sk IN (
        SELECT 
            cs_item_sk 
        FROM 
            catalog_sales 
        WHERE 
            cs_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'MAIL')
    )
WHERE 
    si.tax_percentage > 5.00
ORDER BY 
    sh.total_revenue DESC, si.s_store_name;
