SELECT
    n.n_name AS nation,
    SUM(o.o_totalprice) AS total_revenue
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY
    n.n_name
ORDER BY
    total_revenue DESC
LIMIT 10;