
WITH CustomerStats AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count,
        AVG(cd_credit_rating::int) AS avg_credit_rating
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_gender
),
SalesData AS (
    SELECT
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers
    FROM
        web_sales
    JOIN
        date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
),
StoreStats AS (
    SELECT
        s_store_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        AVG(ss_net_profit) AS avg_net_profit
    FROM
        store_sales
    GROUP BY
        s_store_sk
)
SELECT
    cs.cd_gender,
    cs.customer_count,
    cs.total_purchase_estimate,
    cs.avg_dep_count,
    ss.total_sales AS web_sales_total,
    sd.total_orders AS web_orders,
    sd.unique_customers,
    STRING_AGG(DISTINCT CONCAT(s.s_store_name, ': ', ss.total_store_sales), ', ') AS store_sales_summary
FROM
    CustomerStats cs
JOIN
    SalesData sd ON sd.d_year = (SELECT MAX(d_year) FROM date_dim)
JOIN
    StoreStats ss ON true
GROUP BY
    cs.cd_gender, cs.customer_count, cs.total_purchase_estimate, cs.avg_dep_count, ss.total_sales
ORDER BY
    cs.customer_count DESC;
