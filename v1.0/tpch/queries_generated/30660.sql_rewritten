WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    MAX(l.l_discount) AS max_discount,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(oi.total_order_value) AS avg_order_value,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN (
    SELECT o.o_orderkey, o.o_custkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
) AS oi ON l.l_orderkey = oi.o_orderkey
JOIN customer c ON oi.o_custkey = c.c_custkey
WHERE r.r_name IS NOT NULL 
  AND (n.n_comment IS NULL OR n.n_comment <> '')
  AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT l.l_orderkey) > 10 
       AND SUM(l.l_tax) > 1000
ORDER BY avg_order_value DESC, total_returned_qty ASC;