WITH SupplierPartDetails AS (
    SELECT s.s_name, 
           s.s_address, 
           p.p_name,
           p.p_brand,
           p.p_type,
           ps.ps_supplycost,
           ps.ps_availqty,
           p.p_retailprice,
           CONCAT('Supplier ', s.s_name, ' located at ', s.s_address, ' provides part ', p.p_name, 
                  ' of type ', p.p_type, ' with brand ', p.p_brand, 
                  ', available quantity ', ps.ps_availqty, 
                  ' and supply cost ', FORMAT(ps.ps_supplycost, 2), '.') AS detailed_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT r.r_name AS region_name, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
       STRING_AGG(detailed_info, '; ') AS supplier_part_info
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierPartDetails spd ON s.s_suppkey = spd.s_suppkey
GROUP BY r.r_name
ORDER BY supplier_count DESC;
