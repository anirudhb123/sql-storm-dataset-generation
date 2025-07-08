
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ca.ca_address_sk) AS total_addresses,
        SUM(CASE WHEN ca.ca_state IS NULL THEN 1 ELSE 0 END) AS null_state_count,
        SUM(CASE WHEN cd.cd_dep_count IS NULL THEN 1 ELSE 0 END) AS null_dep_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_id,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory,
        COUNT(DISTINCT CASE WHEN w.w_country IS NULL THEN w.w_warehouse_id END) AS null_country_count
    FROM 
        warehouse w
    LEFT JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_id
),
promotional_activity AS (
    SELECT 
        p.p_promo_id,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS active_discount_cost,
        LISTAGG(p.p_promo_name, ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS promo_names
    FROM 
        promotion p
    WHERE 
        p.p_start_date_sk < p.p_end_date_sk
    GROUP BY 
        p.p_promo_id
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    cs.c_customer_id,
    ws.total_orders,
    ws.total_sales,
    wa.total_inventory,
    pa.active_discount_cost,
    cs.total_addresses,
    cs.null_state_count,
    ROW_NUMBER() OVER (PARTITION BY cs.purchase_rank ORDER BY ws.total_sales DESC) AS sales_rank,
    COALESCE(cs.cd_gender, 'Unknown') AS gender,
    COALESCE(ws.total_orders, 0) - COALESCE(pa.active_discount_cost, 0) AS effective_orders
FROM 
    customer_summary cs
JOIN 
    sales_data ws ON cs.c_customer_sk = ws.ws_item_sk
JOIN 
    warehouse_summary wa ON wa.w_warehouse_sk = ws.ws_item_sk
LEFT JOIN 
    promotional_activity pa ON pa.p_promo_id = cs.c_customer_id
WHERE 
    (pa.active_discount_cost IS NOT NULL OR cs.total_addresses > 1)
    AND (ws.total_sales > 100 OR cs.cd_gender IS NULL)
ORDER BY 
    effective_orders DESC, cs.c_customer_id DESC;
