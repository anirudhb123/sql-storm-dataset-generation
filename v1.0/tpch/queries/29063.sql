SELECT
    p.p_partkey,
    CONCAT(p.p_name, ' - ', p.p_type, ' (', p.p_size, ')') AS full_description,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
    r.r_name AS region_name,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), ', ') AS supplier_info
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
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_partkey, p.p_name, p.p_type, p.p_size, r.r_name
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    total_returned DESC, num_suppliers ASC;