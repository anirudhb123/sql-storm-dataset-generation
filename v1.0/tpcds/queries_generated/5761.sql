
SELECT
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ws_net_paid) AS total_revenue,
    AVG(ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    sm_carrier,
    AVG(DATEDIFF(d_date, MIN(d_date))) AS avg_days_since_first_purchase
FROM
    customer_address AS ca
JOIN
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN
    ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    d.d_year = 2023
GROUP BY
    ca_state, sm_carrier
ORDER BY
    total_revenue DESC
LIMIT 100;
