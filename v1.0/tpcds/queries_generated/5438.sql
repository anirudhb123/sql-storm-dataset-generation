
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
demographic_summary AS (
    SELECT 
        cd.cd_gender,
        SUM(ss.total_spent) AS demographic_spending
    FROM 
        sales_summary ss
    JOIN 
        customer_demographics cd ON ss.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ds.cd_gender,
    ds.demographic_spending,
    RANK() OVER (ORDER BY ds.demographic_spending DESC) AS spending_rank
FROM 
    demographic_summary ds
WHERE 
    ds.demographic_spending > 1000
ORDER BY 
    ds.demographic_spending DESC;
