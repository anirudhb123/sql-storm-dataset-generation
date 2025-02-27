
WITH RECURSIVE top_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
), 
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate
    FROM 
        customer_demographics AS cd
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
), 
sales_summary AS (
    SELECT 
        s.s_store_sk, 
        COUNT(ss.ss_ticket_number) AS total_sales, 
        SUM(ss.ss_net_paid) AS total_revenue
    FROM 
        store_sales AS ss
    JOIN 
        store AS s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cs.total_sales, 
    cs.total_revenue, 
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cs.total_revenue DESC) AS revenue_rank
FROM 
    top_customers AS tc
LEFT JOIN 
    customer AS c ON tc.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    sales_summary AS cs ON cs.s_store_sk = c.c_current_addr_sk
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
    AND cs.total_revenue > 1000
ORDER BY 
    tc.total_spent DESC, 
    revenue_rank ASC;
