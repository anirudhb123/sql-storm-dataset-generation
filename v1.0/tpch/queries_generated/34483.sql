WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
Sales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY o.o_orderkey
),
RankedSales AS (
    SELECT 
        s.o_orderkey,
        s.total_sales,
        s.customer_count,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM Sales s
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.customer_count, 0) AS customer_count,
    sh.level AS supplier_level,
    r.r_name AS region_name,
    COUNT(DISTINCT sh.s_nationkey) AS nation_count
FROM part p
LEFT JOIN RankedSales s ON p.p_partkey = s.o_orderkey
LEFT JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1) LIMIT 1) LIMIT 1)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = r.r_regionkey
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, s.total_sales, s.customer_count, sh.level, r.r_name
HAVING COALESCE(s.total_sales, 0) > 5000
ORDER BY total_sales DESC, p.p_name ASC;
