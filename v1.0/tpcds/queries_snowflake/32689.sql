
WITH RECURSIVE date_series AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date = '2023-01-01'
    UNION ALL
    SELECT dd.d_date_sk, dd.d_date
    FROM date_dim dd
    INNER JOIN date_series ds ON dd.d_date_sk = ds.d_date_sk + 1
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_series)
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating
),
address_summary AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customers_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_state
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_credit_rating,
    COALESCE(asum.customers_count, 0) AS customers_count,
    cs.total_net_profit,
    cs.total_orders,
    ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_net_profit DESC) AS gender_rank
FROM customer_summary cs
LEFT JOIN address_summary asum ON cs.c_customer_sk = asum.ca_address_sk
WHERE cs.total_net_profit > (
    SELECT AVG(total_net_profit) FROM customer_summary
) OR cs.total_orders > (
    SELECT AVG(total_orders) FROM customer_summary
)
ORDER BY cs.total_net_profit DESC
LIMIT 100;
