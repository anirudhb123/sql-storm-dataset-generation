WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartSales AS (
    SELECT 
        p.p_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
GroupedSales AS (
    SELECT 
        ps.p_partkey, 
        COUNT(*) AS sales_count, 
        AVG(total_sales) AS avg_sales
    FROM PartSales ps
    JOIN orders o ON ps.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
    GROUP BY ps.p_partkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    SUM(gs.sales_count) AS total_sales_count,
    AVG(gs.avg_sales) AS avg_sales_per_supplier,
    SUM(CASE 
        WHEN gs.avg_sales > 10000 THEN 1 
        ELSE 0 
    END) AS high_value_sales
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN GroupedSales gs ON gs.p_partkey IN (SELECT p.p_partkey FROM part p)
WHERE sh.level IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING SUM(gs.total_sales) IS NOT NULL
ORDER BY total_sales_count DESC;
