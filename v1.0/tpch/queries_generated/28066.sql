SELECT
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    LTRIM(RTRIM(CONCAT(s.s_name, ' - ', p.p_name))) AS supplier_product,
    SUBSTRING_INDEX(SUBSTRING_INDEX(p.p_comment, ' ', 3), ' ', -3) AS comment_excerpt,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
WHERE
    LENGTH(p.p_name) > 10 AND
    s.s_acctbal > 1000.00 AND
    o.o_orderstatus = 'O'
GROUP BY
    p.p_partkey, s.s_name, c.c_name, o.o_orderkey, p.p_name, p.p_comment
HAVING
    total_revenue > 5000
ORDER BY
    total_revenue DESC;
