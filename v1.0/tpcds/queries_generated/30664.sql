
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        ss_customer_sk,
        SUM(ss_net_profit) AS total_profit,
        1 AS level
    FROM
        store_sales
    GROUP BY
        ss_customer_sk
    
    UNION ALL
    
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        level + 1
    FROM
        web_sales
    JOIN
        sales_hierarchy
    ON
        ws_bill_customer_sk = sales_hierarchy.ss_customer_sk
    GROUP BY
        ws_bill_customer_sk
),
customer_segments AS (
    SELECT
        c.c_customer_sk,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        cd.cd_gender,
        sales_hierarchy.total_profit,
        RANK() OVER (PARTITION BY COALESCE(hd.hd_income_band_sk, 0) ORDER BY sales_hierarchy.total_profit DESC) AS income_rank
    FROM
        customer c
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        sales_hierarchy ON c.c_customer_sk = sales_hierarchy.ss_customer_sk
),
profit_by_income_band AS (
    SELECT
        income_band,
        AVG(total_profit) AS avg_profit,
        COUNT(c_customer_sk) AS customer_count
    FROM
        customer_segments
    GROUP BY
        income_band
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.avg_profit,
    p.customer_count
FROM
    income_band ib
LEFT JOIN
    profit_by_income_band p ON ib.ib_income_band_sk = p.income_band
ORDER BY
    ib.ib_income_band_sk;
