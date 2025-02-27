
WITH SalesData AS (
    SELECT
        w.warehouse_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM
        store_sales ss
    JOIN
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        w.warehouse_name
)
SELECT
    warehouse_name,
    total_sales,
    total_transactions,
    avg_quantity
FROM
    SalesData
ORDER BY
    total_sales DESC;
