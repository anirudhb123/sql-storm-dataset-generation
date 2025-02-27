SELECT
    p.p_name,
    s.s_name,
    n.n_name AS supplier_nation,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    STRING_AGG(DISTINCT r.r_name, ', ') AS served_regions,
    LEFT(s.s_comment, 25) AS short_supplier_comment
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
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_type LIKE '%metal%' AND
    o.o_orderstatus = 'F' AND
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_name, s.s_name, supplier_nation, short_supplier_comment
HAVING
    SUM(ps.ps_availqty) > 100
ORDER BY
    total_available_quantity DESC, avg_extended_price DESC;