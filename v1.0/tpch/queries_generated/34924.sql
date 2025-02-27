WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
RegionalSales AS (
    SELECT n.n_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
),
PartSupplierSales AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY p.p_partkey
)
SELECT 
    sh.s_name,
    n.n_name,
    SUM(ps.total_revenue) AS total_supply_revenue,
    rs.total_sales AS region_sales,
    NULLIF(sh.level, 0) AS supplier_level
FROM SupplierHierarchy sh
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN RegionalSales rs ON n.n_name = rs.n_name
LEFT JOIN PartSupplierSales ps ON sh.s_suppkey = ps.ps_partkey
GROUP BY sh.s_name, n.n_name, rs.total_sales, sh.level
HAVING SUM(ps.total_revenue) IS NOT NULL
ORDER BY region_sales DESC, total_supply_revenue DESC;
