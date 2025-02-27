
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        s_store_sk, ss_sold_date_sk
), 
customer_metrics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_spent,
        COUNT(DISTINCT ws_web_page_sk) AS unique_pages_visited
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
top_customers AS (
    SELECT 
        c.c_customer_sk,
        cm.total_orders,
        cm.total_spent,
        RANK() OVER (ORDER BY cm.total_spent DESC) AS spending_rank
    FROM 
        customer_metrics cm
    INNER JOIN 
        customer c ON cm.c_customer_sk = c.c_customer_sk
    WHERE 
        cm.total_orders > 10
)
SELECT 
    a.ca_country,
    st.s_store_name,
    SUM(ss.ss_net_profit) AS total_store_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returned,
    MAX(tm.t_minute) AS max_transaction_minute,
    STRING_AGG(DISTINCT c_first_name || ' ' || c_last_name, ', ') AS top_customers_names
FROM 
    store st 
LEFT JOIN 
    store_sales ss ON st.s_store_sk = ss.ss_store_sk
LEFT JOIN 
    customer_address a ON st.s_addr_sk = a.ca_address_sk
LEFT JOIN 
    web_sales ws ON st.s_store_sk = ws.ws_warehouse_sk
LEFT JOIN 
    catalog_returns cr ON ss.ss_order_number = cr.cr_order_number
LEFT JOIN 
    time_dim tm ON ss.ss_sold_time_sk = tm.t_time_sk
JOIN 
    top_customers tc ON ws.ws_bill_customer_sk = tc.c_customer_sk
GROUP BY 
    a.ca_country, st.s_store_name
HAVING 
    SUM(ss.ss_net_profit) > 10000
ORDER BY 
    total_store_sales DESC;
