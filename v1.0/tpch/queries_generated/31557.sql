WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 2
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
NationSales AS (
    SELECT n.n_name, SUM(od.total_price) AS total_sales
    FROM nation n
    LEFT JOIN OrderDetails od ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l)))
    GROUP BY n.n_name
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    ns.total_sales,
    COALESCE(SUM(sp.ps_supplycost * sp.ps_availqty), 0) AS total_supplycost,
    DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY ns.total_sales DESC) AS sales_rank
FROM region r
LEFT JOIN nation_sales ns ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE ns.n_nationkey = n.n_nationkey)
LEFT JOIN partsupp sp ON sp.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'Manufacturer#1')
GROUP BY r.r_name, ns.n_name
HAVING ns.total_sales > 10000 OR total_supplycost IS NOT NULL
ORDER BY region, sales_rank;
