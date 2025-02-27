WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, r.r_name AS region_name, 
           ARRAY_AGG(DISTINCT p.p_name) AS supplied_parts,
           STRING_AGG(DISTINCT p.p_brand, ', ') AS brands_supplied,
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, r.r_name
)
SELECT s.s_suppkey, s.s_name, s.region_name, 
       s.supplied_parts, s.brands_supplied, 
       s.total_parts, CAST(s.total_supply_cost AS DECIMAL(12, 2)) AS total_supply_cost
FROM SupplierInfo s
WHERE s.total_parts > 0
ORDER BY s.total_supply_cost DESC
LIMIT 10;
