
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        1 AS level
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
    UNION ALL
    SELECT
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        level + 1
    FROM
        sales_hierarchy sh
    JOIN
        customer c ON sh.c_customer_sk = c.c_current_addr_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
),
sales_summary AS (
    SELECT
        s.ss_customer_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(ss.ss_ticket_number) AS total_sales_count,
        DENSE_RANK() OVER (PARTITION BY s.ss_customer_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
    FROM
        store_sales ss
    GROUP BY
        s.ss_customer_sk
),
date_analysis AS (
    SELECT
        d.d_year,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM
        date_dim d
    JOIN
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY
        d.d_year
)
SELECT
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_gender,
    ch.cd_marital_status,
    ss.total_net_profit,
    ss.avg_sales_price,
    da.unique_customers,
    da.total_profit,
    da.avg_sales_price,
    CASE 
        WHEN ss.total_net_profit IS NULL THEN 'No Profit'
        ELSE 
            CASE 
                WHEN ss.total_net_profit > 1000 THEN 'High Profit'
                WHEN ss.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
                ELSE 'Low Profit'
            END
    END AS profit_category
FROM
    sales_hierarchy ch
LEFT JOIN
    sales_summary ss ON ch.c_customer_sk = ss.ss_customer_sk
JOIN
    date_analysis da ON da.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE
    ch.level <= 2
ORDER BY
    ss.total_net_profit DESC NULLS LAST;
