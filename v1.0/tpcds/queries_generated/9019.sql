
WITH customer_stats AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_gender
),
sales_data AS (
    SELECT
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        ws_sold_date_sk,
        ws_ship_mode_sk
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk,
        ws_ship_mode_sk
),
date_summary AS (
    SELECT
        d_year,
        d_month_seq,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(total_sales) AS monthly_sales,
        SUM(total_profit) AS monthly_profit
    FROM
        sales_data
    JOIN
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY
        d_year,
        d_month_seq
),
final_summary AS (
    SELECT
        ds.d_year,
        ds.d_month_seq,
        ds.total_orders,
        ds.monthly_sales,
        ds.monthly_profit,
        cs.total_customers,
        cs.avg_purchase_estimate,
        cs.avg_dependents,
        cs.married_count
    FROM
        date_summary ds
    CROSS JOIN
        customer_stats cs
    WHERE
        ds.monthly_sales > 10000
)
SELECT
    f.d_year,
    f.d_month_seq,
    f.total_orders,
    f.monthly_sales,
    f.monthly_profit,
    f.total_customers,
    f.avg_purchase_estimate,
    f.avg_dependents,
    f.married_count
FROM
    final_summary f
ORDER BY
    f.d_year DESC,
    f.d_month_seq DESC;
