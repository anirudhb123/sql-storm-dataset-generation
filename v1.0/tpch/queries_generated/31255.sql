WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = sh.s_suppkey)
    WHERE sh.level < 5
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
SalesWindow AS (
    SELECT t.total_sales, RANK() OVER (ORDER BY t.total_sales DESC) AS sales_rank
    FROM TotalSales t
)
SELECT p.p_partkey, p.p_name, COALESCE(s.s_acctbal, 0) AS supplier_acctbal, 
       SUM(l.l_quantity) AS total_quantity,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       (CASE WHEN p.p_retailprice IS NULL THEN 0 ELSE ROUND(SUM(l.l_extendedprice), 2) END) AS total_revenue,
       (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS supplier_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = l.l_suppkey
LEFT JOIN supplier s ON s.s_suppkey = l.l_suppkey
WHERE (sh.level IS NULL OR sh.level <= 3)
GROUP BY p.p_partkey, p.p_name, s.s_acctbal
HAVING SUM(l.l_quantity) > 100
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
