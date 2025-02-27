SELECT
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN l.l_quantity ELSE 0 END) AS total_ordered_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    STRING_AGG(DISTINCT CONCAT(n.n_name, '(', r.r_name, ')'), '; ') AS nation_region_info,
    STRING_AGG(DISTINCT p.p_type, ', ') AS unique_part_types,
    MAX(l.l_shipdate) AS last_shipment_date
FROM
    supplier s
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
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    l.l_shipdate >= '1997-01-01'
GROUP BY
    s.s_name, p.p_name
HAVING
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY
    total_ordered_quantity DESC;