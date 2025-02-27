
SELECT
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON l.l_partkey = p.p_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_retailprice > 50.00
GROUP BY
    p.p_partkey, p.p_name, s.s_name, c.c_name, p.p_comment
HAVING
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY
    order_count DESC;
