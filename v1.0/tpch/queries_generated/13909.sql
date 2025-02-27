SELECT
    l_shipmode,
    COUNT(*) AS count_orders,
    SUM(l_extendedprice) AS total_revenue
FROM
    lineitem
WHERE
    l_shipdate >= DATE '2022-01-01' AND l_shipdate <= DATE '2022-12-31'
GROUP BY
    l_shipmode
ORDER BY
    total_revenue DESC;
