
SELECT
    LOWER(SUBSTRING(p.p_name, 1, 10)) AS truncated_name,
    REPLACE(p.p_comment, 'old', 'new') AS modified_comment,
    CONCAT(s.s_name, ' from ', n.n_name) AS supplier_details,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', c.c_mktsegment, ')'), '; ') AS customer_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_name LIKE '%widget%'
    AND c.c_acctbal > 1000
GROUP BY
    p.p_name, p.p_comment, s.s_name, n.n_name
HAVING
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY
    total_revenue DESC;
