WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_name LIKE 'Supplier%'
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TotalSales AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
AvgSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM TotalSales
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    ss.part_count,
    ss.total_supply_cost,
    ts.total_sales,
    CASE 
        WHEN ts.total_sales > (SELECT avg_sales FROM AvgSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY ss.total_supply_cost DESC) AS supplier_rank,
    COALESCE(SUM(l.l_discount), 0) AS total_discount,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN TotalSales ts ON s.s_suppkey = ts.o_custkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN lineitem l ON l.l_shipdate >= '2023-01-01'
GROUP BY r.r_name, n.n_name, s.s_name, ss.part_count, ss.total_supply_cost, ts.total_sales
ORDER BY r.r_name, n.n_name;
