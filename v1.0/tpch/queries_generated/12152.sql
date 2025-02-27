SELECT
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    o_orderdate
FROM
    lineitem
JOIN
    orders ON l_orderkey = o_orderkey
WHERE
    o_orderdate >= DATE '2021-01-01'
GROUP BY
    l_orderkey, o_orderdate
ORDER BY
    total_revenue DESC
LIMIT 100;
