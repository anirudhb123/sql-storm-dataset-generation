
WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_web_page_sk) AS page_views
    FROM
        web_sales w
    JOIN
        customer c ON w.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_id
),
demographics_summary AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        SUM(cs.cs_net_paid) AS total_catalog_sales
    FROM
        catalog_sales cs
    JOIN
        customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
),
warehouse_summary AS (
    SELECT
        w.w_warehouse_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        warehouse w
    JOIN
        web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY
        w.w_warehouse_id
)
SELECT
    ss.c_customer_id,
    ss.total_sales,
    ss.order_count,
    ds.catalog_order_count,
    ds.total_catalog_sales,
    ws.w_warehouse_id,
    ws.total_web_sales,
    ws.avg_net_profit
FROM
    sales_summary ss
JOIN
    demographics_summary ds ON ss.c_customer_id = ds.catalog_order_count
JOIN
    warehouse_summary ws ON ws.total_web_sales > 1000
ORDER BY
    ss.total_sales DESC, ds.total_catalog_sales DESC;
