
WITH ranked_sales AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2022
    GROUP BY
        ws.web_site_sk, ws.web_name
),
store_summary AS (
    SELECT
        ss.s_store_sk,
        SUM(ss.ss_net_profit) AS total_store_net_profit
    FROM
        store_sales ss
    JOIN
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2022
    GROUP BY
        ss.s_store_sk
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
max_customer_spent AS (
    SELECT
        cs.c_customer_sk,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spender_rank
    FROM
        customer_summary cs
)
SELECT
    r.web_name,
    r.total_net_profit,
    COALESCE(s.total_store_net_profit, 0) AS total_store_net_profit,
    cs.total_orders,
    cs.total_spent,
    CASE
        WHEN r.total_net_profit > 10000 THEN 'High Performer'
        ELSE 'Average Performer'
    END AS performance_category
FROM
    ranked_sales r
LEFT JOIN
    store_summary s ON r.web_site_sk = s.s_store_sk
LEFT JOIN
    customer_summary cs ON cs.total_orders IN (SELECT total_orders FROM customer_summary WHERE total_spent > 1000)
WHERE
    r.profit_rank = 1 OR s.total_store_net_profit IS NOT NULL
ORDER BY
    r.total_net_profit DESC,
    cs.total_spent DESC;
