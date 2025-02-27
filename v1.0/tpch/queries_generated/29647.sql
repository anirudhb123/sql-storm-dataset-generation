SELECT
    SUBSTRING(p_name, 1, 20) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS max_returned_quantity,
    MIN(CASE WHEN l.l_linestatus = 'F' THEN l.l_discount ELSE NULL END) AS min_fulfilled_discount,
    CONCAT(n.n_name, ', ', r.r_name) AS nation_region,
    LEFT(p_comment, 10) AS short_comment
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON l.l_partkey = p.p_partkey
JOIN
    customer c ON c.c_custkey = l.l_orderkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p_size > 10 AND p_retailprice < 100.00
GROUP BY
    short_name, nation_region, short_comment
HAVING
    supplier_count > 5 AND total_available_quantity < 500
ORDER BY
    avg_extended_price DESC, nation_region ASC;
