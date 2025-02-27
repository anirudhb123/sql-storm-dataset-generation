
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rnk
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_date = '2023-01-01'
    )
    GROUP BY ws_bill_customer_sk
    HAVING total_net_profit IS NOT NULL AND total_orders > 0
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_net_profit,
        ss.total_orders
    FROM customer cs
    JOIN sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE ss.rnk <= 10
),
address_info AS (
    SELECT 
        ca.city,
        ca.state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.city, ca.state
),
final_report AS (
    SELECT 
        tc.c_customer_id,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_net_profit,
        tc.total_orders,
        ai.city,
        ai.state,
        COALESCE(ai.customer_count, 0) AS total_customers_in_area
    FROM top_customers tc
    LEFT JOIN address_info ai ON ai.city = 'Los Angeles' AND ai.state = 'CA'
)

SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.total_net_profit,
    f.total_orders,
    f.city,
    f.state,
    f.total_customers_in_area
FROM final_report f
ORDER BY f.total_net_profit DESC;
