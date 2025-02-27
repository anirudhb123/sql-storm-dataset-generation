
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk

    UNION ALL

    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.c_current_cdemo_sk,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM sales_hierarchy sh
    LEFT JOIN web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.c_current_cdemo_sk
),
state_sales AS (
    SELECT 
        ca.ca_state, 
        SUM(ws.ws_net_profit) AS state_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
sales_stats AS (
    SELECT 
        sh.c_first_name,
        sh.c_last_name,
        sh.total_quantity,
        sh.total_profit,
        s.state_profit,
        s.total_orders,
        CONCAT(TRIM(sh.c_first_name), ' ', TRIM(sh.c_last_name)) AS full_name,
        ROW_NUMBER() OVER (PARTITION BY s.state_profit ORDER BY sh.total_profit DESC) AS rank_within_state
    FROM sales_hierarchy sh
    JOIN state_sales s ON s.state_profit > 0
)
SELECT 
    full_name,
    total_quantity,
    total_profit,
    state_profit,
    total_orders
FROM sales_stats
WHERE rank_within_state <= 5
ORDER BY state_profit DESC, total_profit DESC;
