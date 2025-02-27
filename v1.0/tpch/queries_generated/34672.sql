WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
CostAnalysis AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name
),
FilteredOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS adjusted_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' 
      AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
),
RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank_position
    FROM supplier s
)
SELECT 
    COALESCE(p.p_name, 'Unknown Part') AS part_name,
    COALESCE(ca.total_supply_cost, 0.00) AS total_supply_cost,
    COALESCE(fo.adjusted_total, 0.00) AS total_order_value,
    COUNT(DISTINCT sh.s_suppkey) AS distinct_supplier_count,
    COUNT(DISTINCT rs.s_suppkey) AS high_value_supplier_count
FROM part p
LEFT JOIN CostAnalysis ca ON p.p_partkey = ca.p_partkey
LEFT JOIN FilteredOrders fo ON fo.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey = p.p_partkey
)
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = p.p_partkey
LEFT JOIN RankedSuppliers rs ON rs.rank_position <= 10
WHERE p.p_retailprice IS NOT NULL
GROUP BY p.p_partkey, p.p_name, ca.total_supply_cost, fo.adjusted_total
ORDER BY total_supply_cost DESC, total_order_value ASC
LIMIT 50;
