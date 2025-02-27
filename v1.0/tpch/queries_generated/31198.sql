WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.level < 5
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, ROW_NUMBER() OVER (PARTITION BY c.custkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 1000
),
PartSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, p.p_type, RANK() OVER (PARTITION BY p.p_type ORDER BY ps.ps_supplycost ASC) AS rnk
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
)
SELECT 
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_tax) AS avg_tax,
    MAX(sub.rn) AS max_rn,
    COALESCE(MAX(sh.level), 0) AS supplier_hierarchy_level
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN HighValueOrders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = l.l_suppkey
WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 50)
GROUP BY p.p_name
HAVING total_orders > 5
ORDER BY total_revenue DESC
LIMIT 10;
