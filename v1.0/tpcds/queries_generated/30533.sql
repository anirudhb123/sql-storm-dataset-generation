
WITH RECURSIVE sales_totals AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
customer_orders AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        MAX(ws.ws_net_profit) AS max_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
top_stores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_sales_transactions
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    a.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(s.total_sales) AS total_sales_value,
    SUM(co.order_count) AS total_customer_orders,
    AVG(co.avg_order_value) AS average_order_value
FROM 
    customer_address a
LEFT JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    sales_totals s ON s.web_site_sk = c.c_current_cdemo_sk
LEFT JOIN 
    customer_orders co ON co.c_customer_id = c.c_customer_id
WHERE 
    a.ca_state = 'CA'
GROUP BY 
    a.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    total_sales_value DESC
LIMIT 10;
