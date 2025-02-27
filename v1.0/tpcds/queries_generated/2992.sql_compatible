
WITH ranked_sales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_quantity,
        ss_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY ss_net_paid DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                          AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
), 
inventory_levels AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
), 
sales_summary AS (
    SELECT 
        rs.ss_store_sk,
        SUM(rs.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT rs.ss_item_sk) AS distinct_items_sold
    FROM 
        ranked_sales rs
    JOIN 
        inventory_levels il ON rs.ss_item_sk = il.inv_item_sk
    WHERE 
        il.total_quantity_on_hand > 0
    GROUP BY 
        rs.ss_store_sk
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    ss.total_net_paid,
    ss.distinct_items_sold,
    COALESCE(sm.sm_type, 'Unknown') AS shipping_mode
FROM 
    sales_summary ss
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN 
    customer_info cs ON cs.customer_rank <= 10 
    AND ss.distinct_items_sold > 5
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT sr.sm_ship_mode_sk 
                                           FROM store_returns sr 
                                           WHERE sr.sr_store_sk = ss.ss_store_sk 
                                           ORDER BY sr.sr_return_quantity DESC 
                                           LIMIT 1)
WHERE 
    ss.total_net_paid > 1000
ORDER BY 
    ss.total_net_paid DESC, 
    s.s_store_name;
