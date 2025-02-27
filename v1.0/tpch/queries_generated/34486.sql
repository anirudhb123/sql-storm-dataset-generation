WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CAST(s.s_name AS VARCHAR(100)) AS full_path, 
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CAST(CONCAT(sh.full_path, ' > ', s.s_name) AS VARCHAR(100)),
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
TotalSales AS (
    SELECT oi.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM orders oi
    JOIN lineitem li ON oi.o_orderkey = li.l_orderkey
    WHERE oi.o_orderdate >= '2023-01-01'
    GROUP BY oi.o_orderkey
),
SupplierSales AS (
    SELECT ps.ps_partkey, ps.ps_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_sales
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
RankedSales AS (
    SELECT c.c_name, 
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY ts.total_sales DESC) AS sales_rank,
           ts.total_sales
    FROM customer c
    JOIN TotalSales ts ON c.c_custkey = ts.o_orderkey
    WHERE c.c_mktsegment = 'BUILDING'
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    coalesce(sh.full_path, 'No Hierarchy') AS supplier_hierarchy,
    rs.sales_rank,
    rs.total_sales
FROM part p
LEFT JOIN SupplierHierarchy sh ON p.p_partkey = sh.s_suppkey
LEFT JOIN RankedSales rs ON p.p_partkey = rs.sales_rank
WHERE p.p_retailprice BETWEEN 10.00 AND 100.00
  AND (sh.level IS NULL OR sh.level >= 3)
ORDER BY p.p_partkey DESC
FETCH FIRST 50 ROWS ONLY;
