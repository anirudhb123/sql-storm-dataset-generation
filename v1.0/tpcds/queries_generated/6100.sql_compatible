
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    d.d_year,
    d.d_month_seq,
    w.w_warehouse_id,
    sm.sm_carrier,
    COUNT(DISTINCT sr.ticket_number) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk 
                    AND ws.ws_item_sk = sr.sr_item_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, 
    d.d_year, d.d_month_seq, w.w_warehouse_id, sm.sm_carrier
HAVING 
    SUM(ws.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC;
