
WITH ranked_sales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM
        web_sales
),
top_items AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM
        ranked_sales
    WHERE
        rank <= 10
    GROUP BY
        ws_item_sk
),
customer_segment AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        SUM(t.total_net_paid) AS total_spent
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        top_items t ON c.c_customer_sk IN (
            SELECT
                ws_bill_customer_sk
            FROM
                web_sales
            WHERE
                ws_item_sk = t.ws_item_sk
        )
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender
),
monthly_performance AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(c.total_spent) AS total_income
    FROM
        customer_segment c
    JOIN
        date_dim d ON c.total_spent >= 1
    GROUP BY
        d.d_year, d.d_month_seq
)
SELECT
    d.d_year,
    d.d_month_seq,
    COALESCE(mp.unique_customers, 0) AS unique_customers,
    COALESCE(mp.total_income, 0) AS total_income,
    RANK() OVER (ORDER BY COALESCE(mp.total_income, 0) DESC) AS income_rank
FROM
    date_dim d
LEFT JOIN
    monthly_performance mp ON d.d_year = mp.d_year AND d.d_month_seq = mp.d_month_seq
WHERE
    d.d_year >= 2019
ORDER BY
    d.d_year, d.d_month_seq;
