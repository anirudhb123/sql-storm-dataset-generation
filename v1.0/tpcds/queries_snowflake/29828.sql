
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(CASE 
        WHEN cd_gender = 'F' THEN ws_net_profit
        ELSE NULL 
    END) AS avg_female_profit,
    LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), '; ') WITHIN GROUP (ORDER BY c_first_name) AS female_customers_names,
    MAX(d_year) AS latest_year
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    cd_gender = 'F'
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_id) > 0
ORDER BY 
    total_net_profit DESC;
