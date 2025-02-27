SELECT
    CONCAT(s.s_name, ' from ', n.n_name, ' in ', r.r_name) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice ELSE NULL END) AS avg_discounted_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    COUNT(DISTINCT CASE WHEN c.c_mktsegment = 'FURNITURE' THEN c.c_custkey END) AS furniture_customers
FROM
    supplier s
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
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
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    s.s_name, n.n_name, r.r_name
ORDER BY
    total_revenue DESC, total_orders DESC
LIMIT 10;