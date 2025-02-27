
SELECT
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_parts,
    n.n_name AS nation_name,
    r.r_name AS region_name
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
GROUP BY
    c.c_name, n.n_name, r.r_name
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY
    total_revenue DESC;
