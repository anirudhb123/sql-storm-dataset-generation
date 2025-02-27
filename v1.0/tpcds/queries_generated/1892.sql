
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id Order BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), 
top_customers AS (
    SELECT 
        s.c_customer_id,
        s.c_first_name,
        s.c_last_name,
        s.total_profit
    FROM 
        sales_summary s
    WHERE 
        s.profit_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(wp.wp_url, 'No URL') AS last_web_page_accessed,
    SUM(ws.ws_net_paid) AS total_revenue,
    MAX(ws.ws_sold_date_sk) AS last_purchase_date
FROM 
    top_customers tc
LEFT JOIN 
    web_page wp ON wp.wp_customer_sk = tc.c_customer_id
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = tc.c_customer_id
GROUP BY 
    tc.c_customer_id, tc.c_first_name, tc.c_last_name, wp.wp_url
HAVING 
    SUM(ws.ws_net_paid) > 1000 OR last_web_page_accessed IS NOT NULL
ORDER BY 
    total_revenue DESC;
