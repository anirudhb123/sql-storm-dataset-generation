SELECT
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    r.r_name AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(s.s_acctbal) AS average_supplier_balance,
    MAX(l.l_returnflag) AS latest_return_flag,
    STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_name, s.s_name, c.c_name, r.r_name
ORDER BY
    total_revenue DESC
LIMIT 10;