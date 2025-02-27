
WITH RECURSIVE SalesHierarchy AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        SUM(ss.ss_net_profit) AS total_profit
    FROM
        store s
    JOIN
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY
        s.s_store_sk, s.s_store_name, s.s_city, s.s_state, s.s_country
    HAVING
        SUM(ss.ss_net_profit) > 10000
    UNION ALL
    SELECT
        sh.s_store_sk,
        sh.s_store_name,
        sh.s_city,
        sh.s_state,
        sh.s_country,
        SUM(ss.ss_net_profit) AS total_profit
    FROM
        SalesHierarchy sh
    JOIN
        store_sales ss ON sh.s_store_sk = ss.ss_store_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY
        sh.s_store_sk, sh.s_store_name, sh.s_city, sh.s_state, sh.s_country
),
CustomerPreferences AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        cd.cd_gender IS NOT NULL
    GROUP BY
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cp.total_quantity,
        cp.order_count,
        RANK() OVER (PARTITION BY cp.total_quantity ORDER BY cp.order_count DESC) AS customer_rank
    FROM
        CustomerPreferences cp
    JOIN
        customer c ON cp.c_customer_sk = c.c_customer_sk
)
SELECT
    sh.s_store_name,
    sh.s_city,
    sh.s_state,
    sh.total_profit,
    tc.c_first_name,
    tc.c_last_name,
    tc.order_count,
    CASE
        WHEN tc.customer_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM
    SalesHierarchy sh
JOIN
    TopCustomers tc ON sh.s_store_sk = tc.c_customer_sk
ORDER BY
    sh.total_profit DESC,
    tc.order_count DESC;
