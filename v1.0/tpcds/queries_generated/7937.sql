
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_items_sold,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    d.d_year,
    w.w_warehouse_name,
    sm.sm_type
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
JOIN 
    warehouse w ON w.w_warehouse_sk = ss.ss_store_sk
JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = ss.ss_ship_mode_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year, 
    w.w_warehouse_name, 
    sm.sm_type
HAVING 
    SUM(ss.ss_net_profit) > 5000
ORDER BY 
    total_net_profit DESC;
