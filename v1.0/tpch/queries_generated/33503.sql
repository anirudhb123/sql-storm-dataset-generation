WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal AND sh.level < 3
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
NationSuppliers AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    n.n_name AS nation_name, 
    ns.supplier_count, 
    COALESCE(SUM(f.total_sales), 0) AS total_sales, 
    sh.level AS hierarchy_level,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(f.total_sales) DESC) AS sales_rank
FROM NationSuppliers ns
JOIN nation n ON ns.n_nationkey = n.n_nationkey
LEFT JOIN FilteredOrders f ON f.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey IN (SELECT s.s_suppkey FROM SupplierHierarchy sh WHERE sh.level = 2))
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
GROUP BY n.n_name, ns.supplier_count, sh.level
ORDER BY total_sales DESC, n.n_name ASC;
