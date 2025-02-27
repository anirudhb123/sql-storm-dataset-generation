
WITH customer_summary AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY SUM(ws.ws_net_paid) DESC) AS spending_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_spent,
        cs.order_count,
        cs.spending_rank,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) as row_num
    FROM customer_summary cs
    WHERE cs.total_spent IS NOT NULL 
        AND cs.total_spent > (SELECT AVG(total_spent) FROM customer_summary WHERE total_spent IS NOT NULL)
),
customer_addresses AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_city, 
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_zip) AS city_rank
    FROM customer_address ca
),
purchase_details AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_quantity,
        ws.ws_net_profit,
        COALESCE(ws.ws_ext_discount_amt, 0) AS discount,
        p.p_discount_active
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk = (
        SELECT MAX(d.d_date_sk) 
        FROM date_dim d 
        WHERE d.d_date = CURRENT_DATE
    )
)
SELECT 
    tc.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    SUM(pd.ws_net_profit) AS total_net_profit,
    AVG(pd.discount) AS average_discount,
    COUNT(pd.ws_order_number) AS purchases_today,
    MAX(tc.total_spent) AS max_spending,
    MIN(tc.order_count) AS min_orders
FROM top_customers tc
JOIN customer_addresses ca ON tc.c_customer_id = ca.ca_address_id
LEFT JOIN purchase_details pd ON tc.c_customer_id = pd.ws_order_number
WHERE tc.row_num <= 10
GROUP BY tc.c_customer_id, ca.ca_city, ca.ca_state
HAVING COUNT(pd.ws_order_number) > 0
ORDER BY total_net_profit DESC NULLS LAST;
