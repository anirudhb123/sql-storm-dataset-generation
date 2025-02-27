
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
),
customer_info AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_buy_potential
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    cs.total_quantity,
    cs.total_profit,
    ci.ca_city,
    ci.cd_gender,
    ci.cd_buy_potential
FROM customer_hierarchy ch
LEFT JOIN sales_summary cs ON ch.c_customer_sk = cs.bill_customer_sk
LEFT JOIN customer_info ci ON ch.c_customer_sk = ci.c_customer_sk
WHERE cs.total_profit IS NOT NULL
   AND ci.ca_city IS NOT NULL
   AND cs.profit_rank <= 5
ORDER BY ch.level, cs.total_profit DESC;

