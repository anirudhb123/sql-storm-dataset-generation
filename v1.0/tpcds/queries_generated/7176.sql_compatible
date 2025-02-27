
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM
        store_sales ss
    JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        d.d_year, d.d_month_seq
),
customer_summary AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd.cd_credit_rating) AS avg_credit_rating
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender
)
SELECT 
    ss.sales_year,
    ss.sales_month,
    ss.total_sales,
    ss.total_transactions,
    ss.unique_customers,
    ss.avg_net_profit,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.avg_credit_rating
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.sales_year >= 2020
ORDER BY 
    ss.sales_year, ss.sales_month;
