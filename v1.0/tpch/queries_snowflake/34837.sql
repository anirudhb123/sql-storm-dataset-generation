
WITH SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= 50000
),
TotalSales AS (
    SELECT
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
SalesRanked AS (
    SELECT
        c.c_custkey,
        ts.total_sales,
        RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM TotalSales ts
    JOIN customer c ON ts.c_custkey = c.c_custkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    sh.s_name AS supplier_name,
    sh.level,
    COALESCE(ss.total_cost, 0) AS supplier_total_cost,
    CASE 
        WHEN ss.part_count IS NULL THEN 'No Parts'
        ELSE 'Has Parts'
    END AS part_status,
    sr.sales_rank AS customer_sales_rank
FROM SupplierHierarchy sh
FULL OUTER JOIN SupplierStats ss ON sh.s_suppkey = ss.s_suppkey
LEFT JOIN SalesRanked sr ON sr.c_custkey = (SELECT MAX(c.c_custkey)
                                               FROM customer c 
                                               WHERE c.c_nationkey = sh.s_nationkey)
WHERE sh.level < 3
ORDER BY sh.level, supplier_name;
