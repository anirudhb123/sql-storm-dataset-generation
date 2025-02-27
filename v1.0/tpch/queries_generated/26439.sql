SELECT
    p.p_name,
    CONCAT(s.s_name, ' - ', r.r_name) AS supplier_region,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price_per_lineitem,
    COUNT(DISTINCT o.o_orderkey) AS unique_orders,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment
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
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_size > 10
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND r.r_name LIKE 'North%'
GROUP BY
    p.p_name, supplier_region
ORDER BY
    total_quantity DESC, avg_price_per_lineitem ASC
LIMIT 100;
