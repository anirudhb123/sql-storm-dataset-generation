
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk, 
        c.c_current_cdemo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_spent
    FROM customer AS c
    JOIN customer_stats AS cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE cs.total_spent > (
        SELECT AVG(total_spent)
        FROM customer_stats
    )
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address AS ca
    JOIN customer AS c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
),
sales_summary AS (
    SELECT 
        COALESCE(ws.ws_sold_date_sk, cs.cs_sold_date_sk) AS sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales AS ws
    FULL OUTER JOIN catalog_sales AS cs ON ws.ws_item_sk = cs.cs_item_sk
    GROUP BY sold_date_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    a.ca_city,
    a.ca_state,
    cs.total_orders,
    cs.total_spent,
    ss.total_net_profit,
    ss.order_count
FROM high_value_customers AS hvc
JOIN customer_addresses AS a ON hvc.c_customer_sk = a.customer_count
JOIN sales_summary AS ss ON hvc.total_orders > ss.order_count
WHERE a.customer_count IS NOT NULL
ORDER BY hvc.total_spent DESC
LIMIT 50;
