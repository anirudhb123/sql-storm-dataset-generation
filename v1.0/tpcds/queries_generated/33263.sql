
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        0 AS level,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year <= 1990
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag

    UNION ALL

    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        sh.level + 1,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        customer c
    INNER JOIN
        sales_hierarchy sh ON c.c_customer_sk = sh.c_customer_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, sh.level
),
address_summary AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ca.ca_country = 'USA'
    GROUP BY
        ca.ca_state
),
top_states AS (
    SELECT
        ca_state,
        customer_count,
        total_profit,
        RANK() OVER (ORDER BY total_profit DESC) AS state_rank
    FROM
        address_summary
)
SELECT
    sh.c_first_name,
    sh.c_last_name,
    sh.c_preferred_cust_flag,
    sh.total_net_profit,
    ts.ca_state,
    ts.customer_count,
    ts.total_profit
FROM
    sales_hierarchy sh
FULL OUTER JOIN
    top_states ts ON ts.state_rank <= 5
WHERE
    (sh.total_net_profit IS NOT NULL OR ts.total_profit IS NOT NULL)
ORDER BY
    ts.total_profit DESC, sh.total_net_profit DESC;
