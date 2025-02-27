WITH RECURSIVE OrderCTE AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_orderdate DESC) AS rnk
    FROM orders
), PartSuppliers AS (
    SELECT ps_partkey, SUM(ps_supplycost) AS total_supplycost
    FROM partsupp
    GROUP BY ps_partkey
), TopSuppliers AS (
    SELECT ps_partkey, ROW_NUMBER() OVER (ORDER BY total_supplycost DESC) AS rk
    FROM PartSuppliers
), SupplierRegions AS (
    SELECT s.s_suppkey, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT o.o_orderkey, 
       COUNT(DISTINCT l.l_suppkey) AS supplier_count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
       TOP.rk,
       COALESCE(n.n_name, 'Unknown') AS nation_name,
       COALESCE(r.region_name, 'Unknown Region') AS region_name
FROM orders o
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN TopSuppliers TOP ON l.l_partkey = TOP.ps_partkey
LEFT JOIN SupplierRegions sr ON l.l_suppkey = sr.s_suppkey
LEFT JOIN nation n ON sr.nation_name = n.n_name
LEFT JOIN region r ON sr.region_name = r.r_name
WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND (n.n_name IS NOT NULL OR r.r_name IS NULL)
GROUP BY o.o_orderkey, TOP.rk, n.n_name, r.region_name
ORDER BY supplier_count DESC, total_sales DESC;
