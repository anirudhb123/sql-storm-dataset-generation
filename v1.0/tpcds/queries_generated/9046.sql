
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    d.d_year,
    CASE 
        WHEN SUM(ws.ws_quantity) > 100 THEN 'High Volume'
        WHEN SUM(ws.ws_quantity) BETWEEN 51 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    ca.ca_city,
    s.s_state,
    w.w_warehouse_name

FROM customer c
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store s ON ws.ws_ship_addr_sk = s.s_addr_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk

WHERE d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year, 
    ca.ca_city, 
    s.s_state, 
    w.w_warehouse_name

HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_net_profit DESC;
