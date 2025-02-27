WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END AS effective_acctbal,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 0

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END AS effective_acctbal,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 5
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderstatus = 'O'
), TotalSales AS (
    SELECT c.c_custkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), SupplierStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_available,
           COUNT(DISTINCT s.s_nationkey) AS unique_nations
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT p.p_name, 
       COALESCE(ts.total_sales, 0) AS total_sales,
       CASE WHEN th.level IS NULL THEN 'No Hierarchy' ELSE CONCAT('Level ', th.level) END AS supplier_level,
       ss.total_available,
       ss.unique_nations
FROM part p
LEFT JOIN TotalSales ts ON p.p_partkey = ts.c_custkey
LEFT JOIN SupplierStats ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN SupplierHierarchy th ON ss.ps_suppkey = th.s_suppkey AND th.level = (SELECT MAX(level) FROM SupplierHierarchy)
WHERE p.p_retailprice BETWEEN 50 AND 500
ORDER BY total_sales DESC, p.p_name ASC;
