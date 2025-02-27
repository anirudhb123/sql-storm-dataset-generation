WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_partkey) AS unique_parts,
           AVG(l.l_quantity) AS avg_quantity,
           o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationSuppliers AS (
    SELECT n.n_nationkey, n.n_name, 
           COALESCE(SUM(s.s_acctbal), 0) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ns.n_name AS nation_name,
       sh.s_name AS supplier_name,
       os.o_orderkey,
       os.total_sales,
       os.unique_parts,
       os.avg_quantity,
       ns.total_acctbal
FROM NationSuppliers ns
LEFT JOIN SupplierHierarchy sh ON ns.n_nationkey = sh.s_nationkey
JOIN OrderSummary os ON os.total_sales > (SELECT AVG(total_sales) FROM OrderSummary)
WHERE ns.total_acctbal > 10000
ORDER BY ns.n_name, sh.hierarchy_level, os.total_sales DESC
LIMIT 50;
