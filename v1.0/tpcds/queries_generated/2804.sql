
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_spent,
        cs.total_orders,
        cs.avg_order_value,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        customer_stats cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_stats)
),
recently_returned_customers AS (
    SELECT 
        cr.returning_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS total_returned
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        cr.returning_customer_sk
),
customer_summary AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.cd_gender,
        hvc.cd_marital_status,
        hvc.total_spent,
        hvc.total_orders,
        hvc.avg_order_value,
        COALESCE(rr.total_returned, 0) AS total_returned,
        CASE 
            WHEN rr.total_returned > 0 THEN 'Returned'
            ELSE 'Active'
        END AS status
    FROM 
        high_value_customers hvc
    LEFT JOIN 
        recently_returned_customers rr ON hvc.c_customer_sk = rr.customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_spent,
    cs.total_orders,
    cs.avg_order_value,
    cs.total_returned,
    cs.status
FROM 
    customer_summary cs
ORDER BY 
    cs.total_spent DESC, cs.avg_order_value ASC;
