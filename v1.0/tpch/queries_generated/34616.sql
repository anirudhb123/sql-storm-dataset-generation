WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000.00
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 5
),
RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT p.p_partkey, p.p_name, 
       COALESCE(ps.total_availqty, 0) AS total_availqty, 
       sh.level AS supplier_level, 
       rc.r_name, 
       SUM(hl.order_count) AS high_value_order_count
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON p.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_acctbal > 500.00)
)
LEFT JOIN RegionStats rc ON (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = sh.s_nationkey) IS NOT NULL
LEFT JOIN HighValueCustomers hl ON hl.c_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate > '2023-01-01'
)
GROUP BY p.p_partkey, p.p_name, ps.total_availqty, sh.level, rc.r_name
ORDER BY p.p_partkey;
