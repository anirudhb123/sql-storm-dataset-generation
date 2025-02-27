
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(ws_net_paid_inc_tax) AS avg_net_paid_inc_tax,
    COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN c_customer_id END) AS female_customers,
    COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN c_customer_id END) AS male_customers,
    COUNT(DISTINCT s_store_id) AS total_stores,
    SUM(ws_quantity) AS total_sales_quantity,
    d_year,
    d_month_seq
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
JOIN 
    store s ON ws.ws_store_sk = s.s_store_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    ca_state, d_year, d_month_seq
ORDER BY 
    total_net_profit DESC, unique_customers DESC
LIMIT 10;
