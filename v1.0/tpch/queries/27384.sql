SELECT
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(l.l_shipdate) AS latest_shipping_date
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_size > 10 AND
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    s.s_name
ORDER BY
    total_revenue DESC
LIMIT 10;