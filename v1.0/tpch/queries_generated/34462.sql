WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), 
OrderSummary AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS lineitem_count,
           o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
), 
PartSupplierSummary AS (
    SELECT p.p_partkey, 
           SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT r.r_name AS region_name, 
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       SUM(os.total_revenue) AS total_revenue,
       SUM(ps.total_availqty) AS total_availability,
       AVG(ps.avg_supply_cost) AS avg_supply_cost,
       MAX(sh.level) AS max_supplier_level
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey 
                                           FROM orders o 
                                           WHERE o.o_orderdate >= DATE '2023-01-01')
JOIN PartSupplierSummary ps ON ps.p_partkey IN (SELECT l.l_partkey 
                                                 FROM lineitem l 
                                                 JOIN orders o ON o.o_orderkey = l.l_orderkey 
                                                 WHERE o.o_orderdate >= DATE '2023-01-01')
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10 
   AND SUM(os.total_revenue) > 1000000 
   AND MAX(sh.level) IS NOT NULL;
