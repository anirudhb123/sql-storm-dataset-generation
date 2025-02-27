WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
SupplierParts AS (
    SELECT s.s_suppkey,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT n.n_name,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       COALESCE(SUM(ro.total_revenue), 0) AS total_revenue,
       COALESCE(SUM(sp.part_count), 0) AS total_suppliers
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN RankedOrders ro ON c.c_custkey = ro.o_custkey
LEFT JOIN SupplierParts sp ON sp.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_brand LIKE 'Brand#%')
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 0
UNION ALL
SELECT 'Total' AS n_name,
       COUNT(DISTINCT c.c_custkey),
       SUM(ro.total_revenue),
       SUM(sp.part_count)
FROM nation n
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN RankedOrders ro ON c.c_custkey = ro.o_custkey
LEFT JOIN SupplierParts sp ON sp.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_brand LIKE 'Brand#%')
WHERE c.c_acctbal IS NOT NULL
ORDER BY 1;
