
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status IN ('M', 'S')
        AND ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - INTERVAL '30' DAY
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.total_quantity,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        customer_summary c
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.total_quantity,
    tc.total_spent,
    t.d_date,
    wm.wm_manager
FROM 
    top_customers tc
JOIN 
    date_dim t ON t.d_year = 2023
JOIN 
    web_site wm ON wm.web_site_id = 'WS001'
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
