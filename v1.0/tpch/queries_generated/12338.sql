SELECT
    l_shipmode,
    COUNT(*) AS order_count,
    SUM(l_extendedprice) AS total_revenue,
    AVG(l_discount) AS average_discount
FROM
    lineitem
WHERE
    l_shipdate >= DATE '2023-01-01'
    AND l_shipdate < DATE '2024-01-01'
GROUP BY
    l_shipmode
ORDER BY
    order_count DESC;
