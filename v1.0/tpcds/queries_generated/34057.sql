
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_id,
        SUM(ss_net_profit) AS total_profit,
        s_city,
        s_state,
        s_country
    FROM 
        store_sales
    JOIN 
        store ON store.s_store_sk = store_sales.ss_store_sk
    GROUP BY 
        s_store_id, s_city, s_state, s_country
    HAVING 
        SUM(ss_net_profit) > 1000
    UNION ALL
    SELECT 
        sh.s_store_id,
        sh.total_profit + SUM(ws.ws_net_profit) AS total_profit,
        st.s_city,
        st.s_state,
        st.s_country
    FROM 
        sales_hierarchy sh
    JOIN 
        web_sales ws ON ws.ws_ship_addr_sk = (SELECT sr_addr_sk FROM customer WHERE c_customer_sk = %s)
    JOIN 
        store st ON st.s_store_sk = sh.s_store_sk
    GROUP BY 
        sh.s_store_id, sh.total_profit, st.s_city, st.s_state, st.s_country
)
SELECT 
    sh.s_store_id,
    sh.total_profit,
    COUNT(ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
    ROW_NUMBER() OVER(PARTITION BY sh.s_store_id ORDER BY sh.total_profit DESC) AS profit_rank
FROM 
    sales_hierarchy sh
JOIN 
    web_sales ws ON sh.s_store_id = ws.ws_web_site_sk
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = ws.ws_bill_customer_sk)
WHERE 
    sh.total_profit IS NOT NULL
AND 
    (ca.ca_state IS NULL OR ca.ca_state = 'CA')
GROUP BY 
    sh.s_store_id, sh.total_profit
ORDER BY 
    sh.total_profit DESC
LIMIT 10;
