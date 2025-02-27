
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS ranking,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ws.ws_quantity) IS NOT NULL OR COUNT(ws.ws_order_number) IS NULL
),
high_value_customers AS (
    SELECT 
        r.c_customer_sk, 
        r.c_customer_id,
        CASE
            WHEN r.total_quantity > 100 AND r.order_count > 5 THEN 'High Value'
            WHEN r.total_quantity BETWEEN 50 AND 100 AND r.order_count BETWEEN 3 AND 5 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM ranked_customers r
    WHERE r.ranking <= 10
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country,
        CASE 
            WHEN ca.ca_state IN ('CA', 'NY', 'TX') THEN 'High Population State'
            ELSE 'Other State'
        END AS state_category
    FROM customer_address ca
)

SELECT 
    hvc.c_customer_id,
    hvc.customer_value,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COALESCE(COUNT(DISTINCT ca.ca_address_sk), 0) AS address_count,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM high_value_customers hvc
JOIN customer_addresses ca ON hvc.c_customer_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON hvc.c_customer_id = ws.ws_bill_customer_sk
GROUP BY hvc.c_customer_id, hvc.customer_value, ca.ca_city, ca.ca_state, ca.ca_country
HAVING SUM(ws.ws_net_profit) > 1000 OR COUNT(ca.ca_address_sk) = 0
ORDER BY total_net_profit DESC, hvc.c_customer_id;
