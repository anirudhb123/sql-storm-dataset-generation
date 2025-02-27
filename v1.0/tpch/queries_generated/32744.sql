WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > 1000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE sh.hierarchy_level < 3
),
AggregatedSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
),
SupplierSales AS (
    SELECT sh.s_suppkey, sh.s_name, COALESCE(SUM(a.total_sales), 0) AS total_sales
    FROM SupplierHierarchy sh
    LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    LEFT JOIN AggregatedSales a ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice < 100.00)
    GROUP BY sh.s_suppkey, sh.s_name
)
SELECT 
    ss.s_suppkey, 
    ss.s_name, 
    ss.total_sales, 
    CASE 
        WHEN ss.total_sales > 10000 THEN 'Premium'
        WHEN ss.total_sales BETWEEN 5000 AND 10000 THEN 'Standard'
        ELSE 'Basic'
    END AS supplier_tier,
    ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
FROM SupplierSales ss
WHERE ss.total_sales IS NOT NULL 
ORDER BY ss.total_sales DESC, ss.s_name ASC
FETCH FIRST 10 ROWS ONLY;
