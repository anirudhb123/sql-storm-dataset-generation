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
RegionSales AS (
    SELECT r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_name
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemSummary AS (
    SELECT l.l_partkey, COUNT(*) AS total_orders, 
           SUM(l.l_extendedprice) AS total_revenue,
           MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    ps.total_available,
    ps.avg_supply_cost,
    ls.total_orders,
    ls.total_revenue,
    r.total_sales,
    sh.level
FROM part p
JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
JOIN LineItemSummary ls ON p.p_partkey = ls.l_partkey
LEFT JOIN RegionSales r ON p.p_brand = r.r_name
LEFT JOIN SupplierHierarchy sh ON ps.supplier_count >= sh.level
WHERE p.p_retailprice IS NOT NULL 
  AND (p.p_size > 10 OR p.p_type LIKE '%plastic%')
ORDER BY ls.total_revenue DESC, ps.total_available ASC;
