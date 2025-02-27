WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) AND sh.level < 3
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
SalesSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT p.p_partkey, 
       p.p_name, 
       p.p_retailprice, 
       COALESCE(ps.total_cost, 0) AS total_supply_cost,
       COALESCE(ss.total_sales, 0) AS total_sales,
       nh.n_name AS nation_name,
       ROW_NUMBER() OVER (PARTITION BY nh.n_nationkey ORDER BY p.p_retailprice DESC) AS rank_within_nation
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SalesSummary ss ON ss.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Europe%'))
)
LEFT JOIN nation nh ON nh.n_nationkey IN (
    SELECT DISTINCT s_nationkey FROM SupplierHierarchy
)
WHERE p.p_size BETWEEN 10 AND 20
  AND p.p_comment NOT LIKE '%damaged%'
  AND (ps.total_cost IS NOT NULL OR ss.total_sales IS NOT NULL)
ORDER BY nh.n_name, rank_within_nation;
