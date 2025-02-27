WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY total_sales DESC
    LIMIT 5
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
LineItemStats AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           AVG(l.l_tax) AS average_tax
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT ph.p_partkey,
       ph.p_name,
       ps.total_available,
       ls.total_revenue,
       CASE 
           WHEN ls.total_revenue IS NULL THEN 'No Sales'
           WHEN ls.total_revenue > 10000 THEN 'High Performer'
           ELSE 'Low Performer'
       END AS performance_category,
       COALESCE(TH.r_name, 'Unknown Region') AS region_name,
       s.s_name AS supplier_name
FROM PartSupplierStats ps
JOIN part ph ON ps.p_partkey = ph.p_partkey
LEFT JOIN LineItemStats ls ON ph.p_partkey = ls.l_partkey
LEFT JOIN (
    SELECT DISTINCT r.r_name
    FROM TopRegions tr
    JOIN region r ON tr.r_regionkey = r.r_regionkey
) TH ON PH.p_partkey IN (
    SELECT ps.p_partkey
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
)
LEFT JOIN SupplierHierarchy s ON s.s_nationkey IN (
    SELECT n.n_nationkey
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM TopRegions)
)
ORDER BY total_revenue DESC NULLS LAST; 
