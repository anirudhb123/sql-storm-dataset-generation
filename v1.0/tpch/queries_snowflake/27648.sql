
WITH SupplierParts AS (
    SELECT s.s_name AS supplier_name, 
           p.p_name AS part_name, 
           ps.ps_supplycost AS supply_cost,
           p.p_container AS container_type,
           p.p_comment AS part_comment
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT supplier_name, part_name, supply_cost, container_type, part_comment
    FROM SupplierParts
    WHERE supply_cost > 100.00 AND container_type LIKE '%BOX%'
),
RankedSuppliers AS (
    SELECT supplier_name, 
           part_name, 
           supply_cost, 
           container_type, 
           part_comment,
           ROW_NUMBER() OVER (PARTITION BY supplier_name ORDER BY supply_cost DESC) AS rank
    FROM FilteredSuppliers
)
SELECT supplier_name, 
       LISTAGG(part_name || ' (Cost: ' || TO_VARCHAR(supply_cost) || ')', ', ') WITHIN GROUP (ORDER BY supply_cost DESC) AS parts_list, 
       COUNT(part_name) AS total_parts,
       MAX(supply_cost) AS max_supply_cost,
       MIN(supply_cost) AS min_supply_cost,
       SUM(supply_cost) AS total_supply_cost
FROM RankedSuppliers
WHERE rank <= 3
GROUP BY supplier_name
ORDER BY total_supply_cost DESC;
