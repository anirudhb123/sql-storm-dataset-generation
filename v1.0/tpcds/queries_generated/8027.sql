
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cr.cr_reason_sk IS NOT NULL THEN 1 ELSE 0 END) AS total_returns,
    d.d_year AS sales_year, 
    wm.w_warehouse_id AS warehouse_id,
    sm.sm_type AS shipping_method,
    STRING_AGG(DISTINCT p.p_promo_name) AS promotions_used
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    warehouse wm ON ws.ws_warehouse_sk = wm.w_warehouse_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk
LEFT JOIN 
    catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year >= 2022 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, wm.w_warehouse_id, sm.sm_type
ORDER BY 
    total_sales DESC
LIMIT 100;
