
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, c_birth_year,
           1 AS level
    FROM customer
    WHERE c_birth_year IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, c.c_birth_year,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 10
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        MAX(ss.ss_net_profit) AS max_profit
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
address_filter AS (
    SELECT ca_state, COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca_state
    HAVING COUNT(DISTINCT c.c_customer_sk) > 10
)

SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cs.total_sales,
    cs.total_transactions,
    cs.max_profit,
    ah.ca_state,
    ah.customer_count,
    ROW_NUMBER() OVER (PARTITION BY ah.ca_state ORDER BY cs.total_sales DESC) AS state_sales_rank
FROM customer_hierarchy ch
JOIN sales_summary cs ON ch.c_customer_sk = cs.c_customer_sk
JOIN address_filter ah ON ah.customer_count IS NOT NULL
WHERE ch.c_birth_year BETWEEN 1980 AND 1990
AND EXISTS (
    SELECT 1
    FROM store s
    WHERE s.s_store_sk = ss.ss_store_sk
    AND s.s_market_id IN (
        SELECT s_market_id FROM store WHERE s_store_name LIKE 'Super%'
    )
)
ORDER BY total_sales DESC, c_last_name;
