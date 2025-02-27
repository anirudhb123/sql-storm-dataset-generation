
SELECT
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_paid) AS total_sales,
    COUNT(DISTINCT ss_ticket_number) AS total_transactions,
    w.warehouse_name
FROM
    store_sales ss
JOIN
    warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
WHERE
    ss_sold_date_sk BETWEEN 100 AND 200
GROUP BY
    w.warehouse_name
ORDER BY
    total_sales DESC;
