SELECT
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    r.r_name AS region_name,
    n.n_name AS nation_name
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
    p.p_name LIKE 'Steel%' AND
    c.c_acctbal > 1000
GROUP BY
    p.p_name, r.r_name, n.n_name
HAVING
    COUNT(DISTINCT ps.ps_suppkey) > 2
ORDER BY
    total_quantity DESC, p.p_name;
