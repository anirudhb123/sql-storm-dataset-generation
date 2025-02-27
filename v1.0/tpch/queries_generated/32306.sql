WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_acctbal, s2.s_nationkey, s2.s_comment, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE s2.s_acctbal < sh.s_acctbal
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
SupplierTotalSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(ts.total_sales) AS supplier_sales
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN TotalSales ts ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#42' LIMIT 1)
    GROUP BY s.s_suppkey, s.s_name
)
SELECT sh.level, st.supplier_sales, st.s_name, r.r_name
FROM SupplierHierarchy sh
JOIN SupplierTotalSales st ON sh.s_suppkey = st.s_suppkey
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE st.supplier_sales = (
    SELECT MAX(supplier_sales)
    FROM SupplierTotalSales
) 
ORDER BY sh.level DESC, st.supplier_sales DESC
LIMIT 5;
