SELECT
    p.p_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    CONCAT('Region: ', r.r_name, ' | Nation: ', n.n_name) AS location_description,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS combined_comments
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    p.p_retailprice > 100
    AND s.s_acctbal > 5000
    AND l.l_shipdate >= '1997-01-01'
GROUP BY
    p.p_name, s.s_name, n.n_name, r.r_name
ORDER BY
    total_revenue DESC
LIMIT 10;