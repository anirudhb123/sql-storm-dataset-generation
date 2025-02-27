WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rnk
    FROM partsupp ps
    WHERE ps.ps_availqty > 10
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
)
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available,
    COALESCE(SUM(h.revenue), 0) AS total_revenue,
    MAX(sh.level) AS supplier_level
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN HighValueOrders h ON s.s_suppkey = h.o_custkey
LEFT JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
WHERE p.p_size BETWEEN 10 AND 20
GROUP BY p.p_name, s.s_name
HAVING total_available > 50 
   OR (COUNT(h.o_orderkey) > 2 AND MAX(sh.level) IS NOT NULL)
ORDER BY total_revenue DESC, p.p_name;
