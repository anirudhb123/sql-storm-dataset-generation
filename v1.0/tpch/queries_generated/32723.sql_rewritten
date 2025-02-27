WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, 1 AS level
    FROM orders
    WHERE o_orderdate >= DATE '1997-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate >= oh.o_orderdate
),
SupplierSales AS (
    SELECT ps.ps_partkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F' 
    GROUP BY ps.ps_partkey
),
NationSupplierCTE AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, 
       COALESCE(nsc.supplier_count, 0) AS supplier_count,
       nsc.avg_acctbal, 
       ROUND(SUM(ss.total_sales), 2) AS total_sales,
       AVG(CASE WHEN ss.order_count > 0 THEN ss.total_sales ELSE NULL END) AS avg_sales_per_order
FROM region r
LEFT JOIN NationSupplierCTE nsc ON r.r_regionkey = nsc.n_nationkey
LEFT JOIN SupplierSales ss ON nsc.n_nationkey = ss.ps_partkey
GROUP BY r.r_name, nsc.supplier_count, nsc.avg_acctbal
ORDER BY total_sales DESC NULLS LAST, r.r_name ASC;