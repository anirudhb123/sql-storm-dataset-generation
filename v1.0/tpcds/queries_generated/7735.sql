
WITH sales_summary AS (
    SELECT
        d.d_year AS purchase_year,
        d.d_month AS purchase_month,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        AVG(ws.ws_net_profit) AS avg_profit_per_order
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year >= 2020
    GROUP BY
        d.d_year,
        d.d_month
),
demographic_summary AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM
        catalog_sales cs
    JOIN
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_marital_status = 'M' AND
        cd.cd_gender = 'F'
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
)
SELECT
    ss.purchase_year,
    ss.purchase_month,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers,
    ss.avg_profit_per_order,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    ds.total_catalog_sales,
    ds.catalog_order_count
FROM
    sales_summary ss
CROSS JOIN
    demographic_summary ds
ORDER BY
    ss.purchase_year,
    ss.purchase_month,
    ds.total_catalog_sales DESC
LIMIT 100;
