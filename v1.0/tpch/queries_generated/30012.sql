WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, s.s_acctbal, 
           1 AS hierarchy_level
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, s.s_acctbal, 
           sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE sh.hierarchy_level < 3
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT r.r_name, 
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returned,
       COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
       MAX(sh.s_acctbal) AS max_supplier_acctbal,
       STRING_AGG(CONCAT_WS(':', p.p_name, ps.ps_availqty), ', ') AS part_availabilities
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN orders o ON s.s_suppkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN PartSupplierInfo ps ON ps.rn = 1
GROUP BY r.r_name
HAVING SUM(l.l_quantity) > 1000 OR MAX(sh.hierarchy_level) > 1
ORDER BY r.r_name DESC;
