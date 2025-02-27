
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank,
        SUM(ws.ws_net_profit) OVER (PARTITION BY c.c_customer_sk) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) OVER (PARTITION BY c.c_customer_sk) AS order_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate IS NOT NULL
),
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.gender_rank,
        rc.total_spent,
        rc.order_count
    FROM 
        ranked_customers AS rc
    WHERE 
        rc.gender_rank <= 5
)
SELECT 
    tc.c_customer_sk,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS customer_name,
    tc.total_spent,
    CASE 
        WHEN tc.order_count = 0 THEN 'No Orders'
        WHEN tc.order_count BETWEEN 1 AND 5 THEN 'Few Orders'
        ELSE 'Many Orders'
    END AS order_status,
    COALESCE((
        SELECT 
            COUNT(DISTINCT sr.sr_ticket_number) 
        FROM 
            store_returns AS sr 
        WHERE 
            sr.sr_customer_sk = tc.c_customer_sk
            AND sr.sr_return_quantity > 0
    ), 0) AS returns_count
FROM 
    top_customers AS tc
JOIN 
    customer_address AS ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer AS c WHERE c.c_customer_sk = tc.c_customer_sk)
WHERE 
    ca.ca_state IN ('CA', 'NY')
ORDER BY 
    tc.total_spent DESC,
    customer_name ASC;
