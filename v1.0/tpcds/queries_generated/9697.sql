
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ss.ss_net_paid_inc_tax) AS total_spent,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
    d.d_year,
    d.d_month_seq,
    w.w_warehouse_name,
    sm.sm_type
FROM 
    customer AS c
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    store AS s ON ss.ss_store_sk = s.s_store_sk
JOIN 
    warehouse AS w ON s.s_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode AS sm ON ss.ss_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year = 2023
    AND cd.cd_gender = 'F'
    AND ss.ss_net_paid_inc_tax > 100
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    d.d_year, 
    d.d_month_seq, 
    w.w_warehouse_name, 
    sm.sm_type
ORDER BY 
    total_spent DESC
LIMIT 50;
