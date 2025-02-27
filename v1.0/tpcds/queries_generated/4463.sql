
WITH sales_summary AS (
    SELECT 
        cs_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales
    GROUP BY 
        cs_customer_sk
),
top_customers AS (
    SELECT 
        cs_customer_sk,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_online_profit,
    SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_profit,
    COUNT(DISTINCT ws.ws_order_number) AS unique_online_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS unique_store_orders
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    top_customers tc ON c.c_customer_sk = tc.cs_customer_sk
WHERE 
    tc.sales_rank <= 100
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city
HAVING 
    total_online_profit > 1000 OR total_store_profit > 1000
ORDER BY 
    total_online_profit DESC, total_store_profit DESC;
