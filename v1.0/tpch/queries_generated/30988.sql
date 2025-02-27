WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
LastYearOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(YEAR, -1, CURRENT_DATE)
    GROUP BY o.o_orderkey, o.o_orderdate
),
RegionSales AS (
    SELECT n.n_name AS nation_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
RankedSales AS (
    SELECT nation_name, total_sales, RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM RegionSales
)
SELECT 
    s.s_name,
    s.s_acctbal, 
    COALESCE(r.total_sales, 0) AS region_total_sales,
    COALESCE(lyo.total_spent, 0) AS last_year_total_spent
FROM 
    SupplierHierarchy s
LEFT JOIN 
    RankedSales r ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
LEFT JOIN 
    LastYearOrders lyo ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN 
        (SELECT p.p_partkey FROM part p WHERE p.p_size > 10 AND p.p_retailprice IS NOT NULL))
WHERE 
    s.level < 3 AND 
    (s.s_acctbal IS NOT NULL OR r.total_sales IS NOT NULL)
ORDER BY 
    s.s_acctbal DESC, 
    r.sales_rank ASC;
