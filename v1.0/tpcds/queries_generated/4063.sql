
WITH customer_details AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        cd.cd_dep_count, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
recent_orders AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
    GROUP BY 
        ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_amt) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
customer_summary AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        coalesce(ro.total_quantity, 0) AS total_orders, 
        coalesce(ro.total_spent, 0) AS total_spent,
        coalesce(rs.total_returned, 0) AS total_returns
    FROM 
        customer_details cd
    LEFT JOIN 
        recent_orders ro ON cd.c_customer_id = ro.ws_bill_customer_sk
    LEFT JOIN 
        returns_summary rs ON cd.c_customer_id = rs.sr_customer_sk
    WHERE 
        cd.rn = 1
)
SELECT 
    cs.c_customer_id, 
    cs.c_first_name, 
    cs.c_last_name, 
    cs.total_orders, 
    cs.total_spent, 
    cs.total_returns, 
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    customer_summary cs
WHERE 
    cs.total_orders > 5
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
