WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
RankedSales AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice, l.l_discount,
           ROW_NUMBER() OVER(PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
SupplierStats AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS num_suppliers, 
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT r.r_name, COUNT(DISTINCT p.p_partkey) AS num_parts,
       SUM(COALESCE(ts.total, 0)) AS total_sales,
       STRING_AGG(DISTINCT sh.s_name, ', ') AS suppliers,
       MAX(sh.level) AS max_supplier_level,
       COUNT(DISTINCT ss.num_suppliers) AS total_nations
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN part p ON p.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 0
)
LEFT JOIN TotalSales ts ON p.p_partkey = 
    (SELECT l.l_partkey 
     FROM lineitem l 
     WHERE l.l_orderkey = ts.o_orderkey AND l.l_discount < 0.1
     LIMIT 1)
LEFT JOIN SupplierStats ss ON n.n_name = ss.n_name
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
GROUP BY r.r_name
ORDER BY total_sales DESC
LIMIT 10;
