
WITH RECURSIVE sales_summary AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY ss_store_sk

    UNION ALL

    SELECT
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        level + 1
    FROM store_sales ss
    JOIN sales_summary ss_prev ON ss.ss_store_sk = ss_prev.ss_store_sk
    WHERE ss.sold_date_sk < (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY ss_store_sk
),
store_details AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_city,
        s_state,
        s_country,
        w_warehouse_name
    FROM store
    LEFT JOIN warehouse ON store.s_store_sk = warehouse.w_warehouse_sk
),
demographic_analysis AS (
    SELECT
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender
)
SELECT
    sd.s_store_name,
    sd.s_city,
    sd.s_state,
    sd.s_country,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(ss.total_sales, 0) AS total_sales,
    da.avg_purchase_estimate,
    da.customer_count
FROM store_details sd
FULL OUTER JOIN sales_summary ss ON sd.s_store_sk = ss.ss_store_sk
LEFT JOIN demographic_analysis da ON 1=1
WHERE COALESCE(ss.total_sales, 0) > 0
ORDER BY sd.s_country, sd.s_city, total_profit DESC;
