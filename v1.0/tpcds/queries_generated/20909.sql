
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_birth_country,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM ranked_customers rc
    LEFT JOIN web_sales ws ON rc.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY rc.c_customer_sk
    HAVING SUM(ws.ws_net_paid) > (SELECT AVG(purchase_estimate) FROM ranked_customers) 
    OR SUM(ws.ws_net_paid) IS NULL
),
return_summary AS (
    SELECT 
        hvc.c_customer_sk,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM high_value_customers hvc
    LEFT JOIN store_returns sr ON hvc.c_customer_sk = sr.sr_customer_sk
    GROUP BY hvc.c_customer_sk
),
final_return_analysis AS (
    SELECT 
        hvc.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        rs.total_returns,
        CASE 
            WHEN hvc.total_spent IS NULL THEN 'NO SALES'
            WHEN rs.total_returns = 0 THEN 'NO RETURNS'
            ELSE 'MANAGED RETURNS'
        END AS return_status
    FROM high_value_customers hvc
    LEFT JOIN return_summary rs ON hvc.c_customer_sk = rs.c_customer_sk
    LEFT JOIN web_sales ws ON hvc.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY hvc.c_customer_sk, rs.total_returns
)
SELECT 
    f.c_customer_sk,
    f.orders_count,
    f.total_returns,
    f.return_status
FROM final_return_analysis f
WHERE 
    f.total_returns = (
        SELECT MAX(total_returns)
        FROM final_return_analysis
        WHERE return_status = 'MANAGED RETURNS'
    )
ORDER BY 
    f.orders_count DESC,
    f.total_returns DESC
LIMIT 10;
