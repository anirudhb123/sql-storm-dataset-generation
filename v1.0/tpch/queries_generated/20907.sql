WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
    AND sh.level < 5
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, 
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING SUM(s.s_acctbal) > (SELECT AVG(s_acctbal) FROM supplier)
),
LineItemAnalysis AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CustomerTopOrders AS (
    SELECT c.c_custkey, 
           c.c_name,
           o.o_orderkey,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY l.net_value DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN LineItemAnalysis l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
)
SELECT 
    r.r_name,
    COALESCE(t.total_acctbal, 0) AS total_acctbal,
    COALESCE(SUM(l.net_value), 0) AS total_net_value,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT sh.s_suppkey) AS active_suppliers
FROM TopRegions t
FULL OUTER JOIN CustomerTopOrders c ON c.o_orderkey = c.o_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
LEFT JOIN LineItemAnalysis l ON l.l_orderkey = c.o_orderkey
GROUP BY r.r_name, t.total_acctbal
HAVING COUNT(DISTINCT c.c_custkey) > 0 AND SUM(l.net_value) IS NOT NULL
ORDER BY total_net_value DESC, total_acctbal DESC;
