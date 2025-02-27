WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
SalesPerSupplier AS (
    SELECT ps.ps_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_suppkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COALESCE(sp.total_sales, 0) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COALESCE(sp.total_sales, 0) DESC) AS rank
    FROM supplier s
    LEFT JOIN SalesPerSupplier sp ON s.s_suppkey = sp.ps_suppkey
),
NationsWithTopSuppliers AS (
    SELECT n.n_nationkey, n.n_name, r.r_name,
           (SELECT ARRAY_AGG(s.s_name ORDER BY s.total_sales DESC)
            FROM RankedSuppliers s
            WHERE s.rank <= 3 AND s.s_nationkey = n.n_nationkey) AS top_suppliers
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT n.n_name AS nation, r.r_name AS region, 
       STRING_AGG(DISTINCT s) AS best_suppliers
FROM NationsWithTopSuppliers
CROSS JOIN UNNEST(top_suppliers) AS s
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT s) > 0
ORDER BY r.r_name, n.n_name;
