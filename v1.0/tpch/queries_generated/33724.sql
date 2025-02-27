WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplierCount AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
QualifiedSuppliers AS (
    SELECT sh.s_suppkey, sh.s_name, r.r_name, COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM SupplierHierarchy sh
    LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    LEFT JOIN nation n ON sh.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY sh.s_suppkey, sh.s_name, r.r_name
),
RevenueSuppliers AS (
    SELECT qs.s_suppkey, qs.s_name, od.total_revenue
    FROM QualifiedSuppliers qs
    JOIN OrderDetails od ON qs.part_count > 10
)
SELECT qs.s_suppkey, qs.s_name, COALESCE(rs.total_revenue, 0) AS revenue, qs.total_supply_cost
FROM QualifiedSuppliers qs
LEFT JOIN RevenueSuppliers rs ON qs.s_suppkey = rs.s_suppkey
WHERE qs.total_supply_cost > (SELECT AVG(total_supply_cost) FROM QualifiedSuppliers)
ORDER BY revenue DESC, qs.total_supply_cost ASC
LIMIT 10;
