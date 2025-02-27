WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5 AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = sh.s_nationkey)
), OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY o.o_orderkey
), SupplierStats AS (
    SELECT s.s_suppkey, 
           COUNT(ps.ps_partkey) AS supply_count, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), RegionSummary AS (
    SELECT r.r_regionkey,
           r.r_name,
           SUM(COALESCE(ss.avg_supply_cost, 0)) AS total_supply_cost,
           COUNT(DISTINCT ss.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY r.r_regionkey, r.r_name
)

SELECT r.r_name, 
       rs.total_supply_cost, 
       rs.supplier_count, 
       COALESCE(od.order_total, 0) AS total_order_value, 
       sh.level
FROM RegionSummary rs
LEFT JOIN OrderDetails od ON rs.supplier_count > 5 AND od.order_total > 1000
LEFT JOIN SupplierHierarchy sh ON rs.supplier_count = sh.level
WHERE rs.total_supply_cost > 50000
ORDER BY rs.total_supply_cost DESC, total_order_value DESC;
