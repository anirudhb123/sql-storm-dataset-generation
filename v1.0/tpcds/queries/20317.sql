
WITH customer_stats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.order_count,
        cs.total_net_profit,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
    FROM customer_stats cs
    WHERE cs.order_count > (
        SELECT AVG(order_count) FROM customer_stats
    )
)
SELECT
    c.c_customer_id,
    COALESCE(cd.cd_gender, 'Not Specified') AS gender,
    cs.order_count,
    cs.total_net_profit,
    CASE 
        WHEN cs.total_net_profit > 1000 THEN 'High Profit'
        WHEN cs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit' 
    END AS profit_category,
    combinatory_reason AS reason
FROM top_customers cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
CROSS JOIN (
    SELECT STRING_AGG(DISTINCT r.r_reason_desc, ', ') AS combinatory_reason
    FROM reason r
    WHERE r.r_reason_sk IN (
        SELECT DISTINCT sr_reason_sk 
        FROM store_returns sr 
        WHERE sr_return_quantity > 0 
        AND sr_return_amt > 0
    )
) AS r_combination
WHERE cs.order_count IS NOT NULL
AND cs.total_net_profit IS NOT NULL
AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status IN ('M', 'S'))
ORDER BY cs.total_net_profit DESC, c.c_customer_id;
