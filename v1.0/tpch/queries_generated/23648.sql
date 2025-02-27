WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
    HAVING total_revenue > 1000
),
RegionNations AS (
    SELECT n.n_nationkey, r.r_name, n.n_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, rn.r_name
    FROM customer c
    JOIN RegionNations rn ON c.c_nationkey = rn.n_nationkey
    WHERE c.c_acctbal < (SELECT AVG(s.s_acctbal) FROM supplier s WHERE s.s_nationkey = rn.n_nationkey)
),
OrderDetails AS (
    SELECT ho.o_orderkey, ho.total_revenue, fc.c_custkey, fc.r_name
    FROM HighValueOrders ho
    JOIN FilteredCustomers fc ON ho.o_custkey = fc.c_custkey
)
SELECT od.*, 
       CASE 
           WHEN od.r_name IS NULL THEN 'Unknown Region'
           ELSE od.r_name 
       END AS region_label,
       (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = od.o_orderkey AND l.l_returnflag = 'N') AS item_count,
       COALESCE((SELECT SUM(ps.ps_supplycost) 
                 FROM partsupp ps 
                 WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey)), 0) AS total_supply_cost
FROM OrderDetails od
LEFT JOIN RankedSuppliers rs ON rs.s_suppkey = (SELECT ps.ps_suppkey 
                                                FROM partsupp ps 
                                                WHERE ps.ps_partkey IN 
                                                      (SELECT l.l_partkey 
                                                       FROM lineitem l 
                                                       WHERE l.l_orderkey = od.o_orderkey) 
                                                ORDER BY ps.ps_supplycost DESC 
                                                FETCH FIRST 1 ROW ONLY)
WHERE od.total_revenue IS NOT NULL
ORDER BY od.total_revenue DESC, item_count DESC NULLS LAST;
