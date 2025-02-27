WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.suppkey <> sh.s_suppkey
)

SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(p.p_retailprice) AS average_part_price,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY total_revenue DESC) AS revenue_rank,
    MAX(s.s_acctbal) AS max_supplier_balance
FROM nation n
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE l.l_shipdate >= DATE '2023-01-01'
  AND l.l_returnflag = 'N'
  AND (s.s_acctbal IS NULL OR s.s_acctbal > 0)
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY revenue_rank, total_revenue DESC;
