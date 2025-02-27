
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    sm.sm_carrier,
    sm.sm_type,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
    SUM(sr.sr_return_amt) AS total_returns,
    COALESCE(SUM(ws.ws_sales_price), 0) - COALESCE(SUM(sr.sr_return_amt), 0) AS net_sales
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN 
    store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number
JOIN 
    ship_mode sm ON ss.ss_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, d.d_day_name, sm.sm_carrier, sm.sm_type
ORDER BY 
    total_sales DESC
LIMIT 100;
