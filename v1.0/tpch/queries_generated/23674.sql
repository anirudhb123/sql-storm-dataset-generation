WITH recursive SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * l.l_quantity) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * l.l_quantity) > 10000
),
RegionOrderCounts AS (
    SELECT n.n_regionkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_regionkey
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name
    FROM region r
    JOIN RegionOrderCounts roc ON r.r_regionkey = roc.n_regionkey
    WHERE roc.order_count > (SELECT AVG(order_count) FROM RegionOrderCounts)
),
PartSupplierDetail AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
           SUM(ps.ps_availqty) AS total_avail_qty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_size BETWEEN 1 AND 20
    GROUP BY p.p_partkey, p.p_name, p.p_brand
)
SELECT p.p_partkey, p.p_name, p.p_brand, p.total_avail_qty, ss.total_sales, r.r_name AS region_name
FROM PartSupplierDetail p
LEFT JOIN SupplierSales ss ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey
)
JOIN TopRegions r ON ss.s_suppkey IN (
    SELECT s.s_suppkey
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_partkey = p.p_partkey
)
ORDER BY CASE
             WHEN p.total_avail_qty IS NULL THEN 1
             WHEN p.total_avail_qty < 50 THEN 2
             ELSE 0
         END, 
         p.p_name ASC;
