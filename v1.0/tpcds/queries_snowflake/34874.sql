
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
    HAVING
        SUM(ws_net_profit) > 0
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
date_series AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        ROW_NUMBER() OVER (ORDER BY d.d_date) AS day_sequence
    FROM
        date_dim d
    WHERE
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cs.total_quantity,
    cs.total_net_profit,
    ct.day_sequence,
    CASE
        WHEN cs.rank <= 10 THEN 'Top Seller'
        WHEN cs.rank <= 30 THEN 'Moderate Seller'
        ELSE 'Low Seller'
    END AS sales_category
FROM
    customer_details c
JOIN
    sales_summary cs ON cs.ws_item_sk IN (
        SELECT ws_item_sk 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = c.c_customer_sk
    )
JOIN
    date_series ct ON ct.d_date_sk = (
        SELECT MAX(d.d_date_sk)
        FROM date_dim d
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE ws.ws_bill_customer_sk = c.c_customer_sk
        AND EXTRACT(YEAR FROM d.d_date) = 2023
    )
ORDER BY
    cs.total_net_profit DESC, c.c_last_name, c.c_first_name;
