
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_year,
        c_current_cdemo_sk,
        1 AS level
    FROM
        customer
    WHERE
        c_birth_year >= 1990

    UNION ALL

    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_current_cdemo_sk,
        sh.level + 1
    FROM
        customer c
    JOIN sales_hierarchy sh ON sh.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE
        c.c_birth_year >= 1990
)

SELECT
    ca.city,
    ca.state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(ws.ws_net_paid) AS max_net_paid,
    MIN(CASE WHEN ws.ws_ext_discount_amt IS NULL THEN 0 ELSE ws.ws_ext_discount_amt END) AS min_discount_amt
FROM
    customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE
    ca.ca_state IN ('NY', 'CA')
    AND c.c_birth_year >= 1990
    AND EXISTS (
        SELECT 1
        FROM sales_hierarchy sh
        WHERE sh.c_customer_sk = c.c_customer_sk
        HAVING COUNT(*) > 1
    )
GROUP BY
    ca.city, ca.state
HAVING
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY
    total_net_profit DESC
LIMIT 50;
