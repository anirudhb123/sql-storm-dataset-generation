SELECT
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier,
    p.p_name AS part_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    cast('1998-10-01' as date) AS query_date
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
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
    r.r_comment LIKE '%global%'
    AND s.s_comment NOT LIKE '%obsolete%'
    AND l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY
    r.r_name, n.n_name, s.s_name, p.p_name
ORDER BY
    total_revenue DESC, region, nation, supplier, part_name
LIMIT 100;