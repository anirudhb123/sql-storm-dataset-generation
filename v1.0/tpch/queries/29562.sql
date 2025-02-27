SELECT
    CONCAT(c.c_name, ' - ', n.n_name) AS customer_nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_shipping_date,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names_handled
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
WHERE
    n.n_name LIKE '%land%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    c.c_name, n.n_name
ORDER BY
    total_revenue DESC
LIMIT 10;