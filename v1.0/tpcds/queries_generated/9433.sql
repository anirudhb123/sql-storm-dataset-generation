
SELECT 
    ca.city AS customer_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(ws.net_profit) AS total_net_profit,
    AVG(cd.purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    DATE_FORMAT(d.d_date, '%Y-%m') AS order_month,
    sm.sm_type AS ship_mode,
    ib.ib_lower_bound AS income_band_lower,
    ib.ib_upper_bound AS income_band_upper
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    d.d_year = 2022 
GROUP BY 
    ca.city, 
    DATE_FORMAT(d.d_date, '%Y-%m'), 
    sm.sm_type, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound
ORDER BY 
    total_net_profit DESC, 
    total_customers DESC
LIMIT 100;
