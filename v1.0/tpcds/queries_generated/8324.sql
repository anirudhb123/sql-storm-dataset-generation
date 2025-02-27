
WITH sales_summary AS (
    SELECT
        s.s_store_sk,
        w.w_warehouse_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM
        store_sales ss
    JOIN
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN
        warehouse w ON s.s_store_sk = w.w_warehouse_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        s.s_store_sk, w.w_warehouse_name
),
customer_summary AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT ss.ss_customer_sk) AS customers_count,
        AVG(ss.ss_sales_price) AS avg_spending
    FROM
        customer_demographics cd
    JOIN
        store_sales ss ON cd.cd_demo_sk = ss.ss_cdemo_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender
),
final_summary AS (
    SELECT
        ss.warehouse_name,
        cs.cd_gender,
        ss.total_sales,
        cs.customers_count,
        cs.avg_spending,
        RANK() OVER (PARTITION BY ss.warehouse_name ORDER BY ss.total_sales DESC) AS sales_rank
    FROM
        sales_summary ss
    JOIN
        customer_summary cs ON ss.s_store_sk = cs.cd_demo_sk
)
SELECT
    warehouse_name,
    cd_gender,
    total_sales,
    customers_count,
    avg_spending,
    sales_rank
FROM
    final_summary
WHERE
    sales_rank <= 10
ORDER BY
    warehouse_name, total_sales DESC;
