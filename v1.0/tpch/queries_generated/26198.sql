WITH PartSupplier AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, s.s_suppkey, s.s_name, s.s_nationkey,
           CONCAT(p.p_name, ' (', p.p_brand, ') [', p.p_type, '] - Supplied by ', s.s_name) AS part_info,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_name) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
RegionNation AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name,
           CONCAT(n.n_name, ' from ', r.r_name) AS full_location
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT ps.part_info, rn.full_location, 
       COUNT(*) AS supplier_count,
       STRING_AGG(CONCAT(rn.full_location, ': ', ps.part_info), '; ') AS supplier_details
FROM PartSupplier ps
JOIN RegionNation rn ON ps.s_nationkey = rn.n_nationkey
WHERE ps.rn = 1
GROUP BY ps.part_info, rn.full_location
ORDER BY supplier_count DESC, ps.part_info;
