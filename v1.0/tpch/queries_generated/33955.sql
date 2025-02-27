WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level 
    FROM supplier 
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1 
    FROM supplier s 
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE s.s_acctbal > sh.s_acctbal
), FilteredParts AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 10 AND 20
    GROUP BY p.p_partkey, p.p_name
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, COUNT(li.l_orderkey) AS lineitem_count
    FROM orders o
    LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_totalprice > 5000
    GROUP BY o.o_orderkey, o.o_totalprice
    HAVING COUNT(li.l_orderkey) > 1
)
SELECT rh.r_name, 
       COUNT(DISTINCT ch.c_custkey) AS num_customers,
       SUM(fo.o_totalprice) AS total_value,
       SUM(COALESCE(fp.avg_supplycost, 0)) AS total_supplycost
FROM region rh
LEFT JOIN nation n ON n.n_regionkey = rh.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN Customer ch ON ch.c_nationkey = n.n_nationkey 
LEFT JOIN HighValueOrders fo ON ch.c_custkey = fo.o_orderkey
LEFT JOIN FilteredParts fp ON fp.p_partkey = s.s_suppkey
JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE rh.r_name IS NOT NULL
GROUP BY rh.r_name 
ORDER BY total_value DESC
LIMIT 10;
