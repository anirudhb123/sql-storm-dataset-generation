
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, COUNT(ps.ps_partkey) AS supply_count,
           SUM(ps.ps_availqty) AS total_availqty, SUM(ps.ps_supplycost) AS total_supplycost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredRegions AS (
    SELECT r.r_regionkey, r.r_name
    FROM region r
    WHERE r.r_name LIKE 'Middle%'
),
PopularParts AS (
    SELECT p.p_partkey, p.p_name, COUNT(l.l_orderkey) AS order_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(l.l_orderkey) > 100
)
SELECT f.r_name AS region_name, 
       supplier.s_name AS supplier_name, 
       popular.p_name AS part_name,
       supplier.total_availqty,
       supplier.total_supplycost,
       STRING_AGG(DISTINCT CONCAT(n.n_name, ' (', n.n_nationkey, ')'), ', ') AS nations
FROM FilteredRegions f
JOIN RankedSuppliers supplier ON supplier.s_nationkey IN (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_regionkey = f.r_regionkey
) AND supplier.rn = 1
JOIN PopularParts popular ON popular.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey = supplier.s_suppkey
)
JOIN nation n ON supplier.s_nationkey = n.n_nationkey
GROUP BY f.r_name, supplier.s_name, popular.p_name, supplier.total_availqty, supplier.total_supplycost
ORDER BY region_name, supplier_name;
