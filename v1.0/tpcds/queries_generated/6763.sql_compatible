
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ticket_number) AS total_sales,
        SUM(ss.ss_sales_price) AS total_spent,
        AVG(ss.ss_sales_price) AS avg_spent_per_transaction,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status
),
SalesPerformance AS (
    SELECT
        cs.cd_gender,
        cs.cd_marital_status,
        COUNT(*) AS customer_count,
        SUM(cs.total_sales) AS total_sales,
        SUM(cs.total_spent) AS total_spent,
        AVG(cs.avg_spent_per_transaction) AS avg_spent_per_transaction,
        SUM(cs.total_returns) AS total_returns,
        SUM(cs.total_returned) AS total_returned
    FROM
        CustomerStats cs
    GROUP BY
        cs.cd_gender,
        cs.cd_marital_status
)
SELECT
    sp.cd_gender,
    sp.cd_marital_status,
    sp.customer_count,
    sp.total_sales,
    sp.total_spent,
    sp.avg_spent_per_transaction,
    sp.total_returns,
    sp.total_returned,
    (sp.total_spent / NULLIF(sp.total_sales, 0)) AS avg_spent_per_sale,
    (sp.total_spent - sp.total_returned) AS net_spent
FROM
    SalesPerformance sp
ORDER BY
    sp.total_spent DESC;
