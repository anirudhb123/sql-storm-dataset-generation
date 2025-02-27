WITH RECURSIVE HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    JOIN HighValueSuppliers hvs ON s.s_suppkey = hvs.s_suppkey
    WHERE s.s_acctbal > hvs.s_acctbal * 0.9
), 
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '2 months'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
),
DistinctCustomers AS (
    SELECT DISTINCT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    LEFT JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
    WHERE ro.o_orderstatus IS NULL OR ro.total_revenue > 50000
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT r.r_name, 
       COUNT(DISTINCT ns.n_nationkey) AS nations_count,
       SUM(DISTINCT CASE WHEN ps.ps_supplycost < 30 THEN ps.ps_availqty ELSE 0 END) AS total_available_qty,
       MAX(pvi.avg_supply_cost) AS max_avg_cost,
       (SELECT COUNT(*) FROM HighValueSuppliers) AS high_value_suppliers_count
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN PartSupplierInfo pvi ON ns.n_nationkey = 
      (SELECT n.n_nationkey 
       FROM nation n 
       WHERE n.n_name LIKE '%' || 'land' || '%'
       LIMIT 1)
FULL OUTER JOIN RecentOrders ro ON ro.o_custkey IN 
      (SELECT c.c_custkey 
       FROM DistinctCustomers c
       WHERE c.c_acctbal IS NOT NULL
       AND c.c_acctbal > 50000)
GROUP BY r.r_name
HAVING COUNT(DISTINCT ns.n_nationkey) > 1 
   OR MAX(pvi.avg_supply_cost) IS NULL
ORDER BY r.r_name DESC
LIMIT 10;
