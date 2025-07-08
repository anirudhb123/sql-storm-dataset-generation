
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_bill_customer_sk, 
        ws_item_sk, 
        ws_order_number, 
        ws_net_profit,
        1 AS depth
    FROM web_sales
    WHERE ws_net_profit > 100

    UNION ALL

    SELECT 
        c.c_customer_sk, 
        w.ws_item_sk, 
        w.ws_order_number, 
        w.ws_net_profit,
        sh.depth + 1
    FROM sales_hierarchy sh
    JOIN web_sales w ON sh.ws_item_sk = w.ws_item_sk
    JOIN customer c ON w.ws_bill_customer_sk = c.c_customer_sk
    WHERE sh.depth < 5 
    AND w.ws_net_profit < sh.ws_net_profit
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        COUNT(DISTINCT c.c_customer_id) AS city_customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city
),
profit_summary AS (
    SELECT 
        ci.c_customer_sk, 
        ci.total_profit,
        ai.city_customer_count,
        DENSE_RANK() OVER (ORDER BY ci.total_profit DESC) AS profit_rank
    FROM customer_info ci
    JOIN address_info ai ON ci.c_customer_sk = ai.ca_address_sk
    WHERE ci.total_profit IS NOT NULL
)
SELECT 
    ps.profit_rank,
    ps.total_profit,
    ps.city_customer_count,
    COALESCE(NULLIF(ps.total_profit / NULLIF(ps.city_customer_count, 0), 0), 0) AS profit_per_customer
FROM profit_summary ps
WHERE ps.profit_rank <= 20
ORDER BY ps.profit_rank;
