WITH RECURSIVE RegionHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS level
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, r.level + 1
    FROM nation n
    JOIN RegionHierarchy r ON n.n_regionkey = r.n_nationkey
),
TotalSales AS (
    SELECT c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
SupplierStats AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.r_name,
           ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT rh.n_name AS nation_name, 
       COALESCE(SUM(ts.total_revenue), 0) AS total_revenue,
       COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
       COALESCE(MAX(ts.total_revenue), 0) AS max_revenue,
       COUNT(DISTINCT ts.c_custkey) AS customer_count,
       COUNT(DISTINCT ts.c_custkey) FILTER (WHERE COALESCE(ss.supplier_count, 0) > 0) AS customers_with_suppliers
FROM RegionHierarchy rh
LEFT JOIN TotalSales ts ON rh.n_nationkey = ts.c_custkey
LEFT JOIN SupplierStats ss ON ss.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_mfgr LIKE 'Manufacturer%')
GROUP BY rh.n_name
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
