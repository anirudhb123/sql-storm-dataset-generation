
WITH ranked_store_sales AS (
    SELECT
        ss.s_store_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss.s_store_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS rn
    FROM
        store_sales ss
    JOIN
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate > 100
    GROUP BY
        ss.s_store_sk
),
top_stores AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        rs.total_sales,
        rs.transaction_count
    FROM
        ranked_store_sales rs
    JOIN
        store s ON rs.s_store_sk = s.s_store_sk
    WHERE
        rs.rn = 1
)
SELECT
    ts.s_store_id,
    ts.s_store_name,
    ts.total_sales,
    ts.transaction_count,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amt
FROM
    top_stores ts
LEFT JOIN
    store_returns sr ON ts.s_store_sk = sr.s_store_sk
GROUP BY
    ts.s_store_id, ts.s_store_name, ts.total_sales, ts.transaction_count
HAVING
    ts.total_sales > 1000
ORDER BY
    ts.total_sales DESC;
