
WITH TotalSales AS (
    SELECT
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COALESCE(SUM(ws_quantity), 0) AS total_web_quantity,
        COALESCE(SUM(cs_quantity), 0) AS total_catalog_quantity,
        COALESCE(SUM(ss_quantity), 0) AS total_store_quantity
    FROM
        web_sales
    FULL OUTER JOIN catalog_sales ON ws_order_number = cs_order_number
    FULL OUTER JOIN store_sales ON ws_order_number = ss_ticket_number
),
Demographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_gender, cd_marital_status
),
SalesDetails AS (
    SELECT
        d_year,
        d_month_seq,
        DENSE_RANK() OVER (ORDER BY d_year, d_month_seq) AS month_rank,
        SUM(ws_ext_sales_price) AS web_sales,
        SUM(cs_ext_sales_price) AS catalog_sales,
        SUM(ss_ext_sales_price) AS store_sales
    FROM
        date_dim
    LEFT JOIN web_sales ON d_date_sk = ws_sold_date_sk
    LEFT JOIN catalog_sales ON d_date_sk = cs_sold_date_sk
    LEFT JOIN store_sales ON d_date_sk = ss_sold_date_sk
    GROUP BY
        d_year, d_month_seq
)

SELECT
    d.d_year,
    d.d_month_seq,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales,
    s.total_web_quantity,
    s.total_catalog_quantity,
    s.total_store_quantity,
    d.customer_count,
    d.avg_purchase_estimate
FROM
    TotalSales s
JOIN SalesDetails d ON d.month_rank <= 12
JOIN Demographics de ON de.cd_gender = 'M'
ORDER BY
    d.d_year DESC,
    d.d_month_seq DESC
LIMIT 100;
