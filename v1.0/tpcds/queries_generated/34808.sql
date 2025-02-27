
WITH RECURSIVE sales_data AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        d.d_date AS purchase_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date DESC) AS order_rank
    FROM 
        sales_data sd
    JOIN 
        customer c ON sd.c_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        sd.rank <= 10 
        AND d.d_year = 2022
)
SELECT 
    tc.c_customer_id,
    COUNT(tc.purchase_date) AS orders_in_2022,
    MAX(tc.purchase_date) AS last_order_date,
    AVG(sd.total_profit) AS avg_profit_per_order,
    SUM(COALESCE(sr_return_amt, 0)) AS total_returns,
    COUNT(DISTINCT CASE WHEN wp.wp_web_page_id IS NOT NULL THEN wp.wp_web_page_id END) AS distinct_webpage_views
FROM 
    top_customers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN 
    store_returns sr ON tc.c_customer_id = sr.sr_customer_sk
JOIN 
    sales_data sd ON sd.c_customer_sk = tc.c_customer_sk
GROUP BY 
    tc.c_customer_id
HAVING 
    COUNT(tc.purchase_date) > 0
ORDER BY 
    orders_in_2022 DESC;
