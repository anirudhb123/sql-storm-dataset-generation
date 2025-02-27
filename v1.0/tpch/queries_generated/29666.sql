SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name SEPARATOR ', '), ', ', 5) AS top_suppliers,
    c.c_mktsegment,
    r.r_name AS region
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
JOIN orders o ON o.o_orderkey = l.l_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_type LIKE '%brass%'
  AND r.r_name IN ('EUROPE', 'ASIA')
  AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY p.p_partkey, c.c_mktsegment, r.r_name
HAVING total_revenue > 10000
ORDER BY total_revenue DESC, supplier_count DESC;
