
WITH customer_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        count(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
top_customers AS (
    SELECT
        cs.c_customer_id,
        cs.total_orders,
        cs.total_profit,
        CASE 
            WHEN cs.total_profit IS NULL THEN 'Unknown'
            WHEN cs.total_profit > 10000 THEN 'High Value'
            WHEN cs.total_profit BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_segment
    FROM customer_stats cs
    WHERE cs.total_orders > 0
),
customer_addresses AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_address_sk) AS rn
    FROM customer_address ca
)
SELECT
    tc.c_customer_id,
    tc.total_orders,
    tc.total_profit,
    tc.value_segment,
    ca.ca_city,
    ca.ca_state
FROM top_customers tc
LEFT JOIN customer_addresses ca ON tc.c_customer_id = (
    SELECT c.c_customer_id
    FROM customer c
    WHERE c.c_current_addr_sk = ca.ca_address_sk
    LIMIT 1
)
WHERE (ca.ca_state IS NOT NULL OR tc.total_profit > 5000)
ORDER BY tc.total_profit DESC, tc.total_orders ASC
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT 
    'Aggregated' AS c_customer_id,
    COUNT(*) AS total_orders,
    SUM(total_profit) AS total_profit,
    'Aggregate Value' AS value_segment,
    NULL AS ca_city,
    NULL AS ca_state
FROM top_customers
WHERE total_profit IS NOT NULL
HAVING SUM(total_profit) > 0
ORDER BY total_profit DESC;
