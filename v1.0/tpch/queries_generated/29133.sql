SELECT
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS total_sales,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    r.r_name
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    customer c ON c.c_custkey = l.l_orderkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_size > 5
    AND l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    AND c.c_mktsegment = 'Retail'
GROUP BY
    p.p_name, r.r_name
ORDER BY
    total_sales DESC, supplier_count DESC
LIMIT 10;
