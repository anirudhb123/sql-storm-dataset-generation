SELECT
    p.p_name,
    s.s_name,
    c.c_name,
    COUNT(*) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS average_discount,
    MIN(l.l_tax) AS min_tax,
    MAX(l.l_tax) AS max_tax,
    (SELECT COUNT(DISTINCT o.o_orderkey)
     FROM orders o
     WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31') AS total_yearly_orders
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    customer c ON c.c_nationkey = s.s_nationkey
WHERE
    p.p_comment LIKE '%special%' AND
    l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY
    p.p_name, s.s_name, c.c_name
HAVING
    total_orders > 10
ORDER BY
    total_revenue DESC;
