
WITH RECURSIVE sales_summary AS (
    SELECT
        ss.sold_date_sk,
        ss.store_sk,
        ss.item_sk,
        SUM(ss.ext_sales_price) AS total_sales,
        COUNT(ss.ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY SUM(ss.ext_sales_price) DESC) AS sales_rank
    FROM
        store_sales ss
    WHERE
        ss.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY
        ss.sold_date_sk, ss.store_sk, ss.item_sk
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender
)
SELECT
    cs.c_customer_sk,
    cs.cd_gender,
    cs.total_web_sales,
    ss.store_sk,
    ss.item_sk,
    ss.total_sales,
    ss.total_transactions
FROM
    customer_summary cs
JOIN sales_summary ss ON cs.c_customer_sk IN (
    SELECT DISTINCT ws.ws_bill_customer_sk
    FROM web_sales ws
    WHERE ws.sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    )
WHERE
    cs.total_web_sales > (
        SELECT AVG(total_web_sales) FROM customer_summary
    )
ORDER BY
    cs.total_web_sales DESC,
    ss.total_sales DESC
LIMIT 100;

