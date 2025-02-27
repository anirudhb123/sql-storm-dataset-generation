WITH SupplierParts AS (
    SELECT s.s_name AS supplier_name, 
           p.p_name AS part_name, 
           ps.ps_availqty AS available_quantity,
           ps.ps_supplycost AS supply_cost,
           CONCAT(s.s_address, ', ', n.n_name) AS supplier_location
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE p.p_type LIKE '%metal%' 
      AND ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
),

AggregatedSupplierData AS (
    SELECT supplier_name, 
           COUNT(part_name) AS parts_supplied, 
           SUM(available_quantity) AS total_available_quantity,
           ROUND(AVG(supply_cost), 2) AS avg_supply_cost,
           STRING_AGG(part_name, ', ') AS part_names_list
    FROM SupplierParts
    GROUP BY supplier_name
)

SELECT supplier_name, 
       parts_supplied, 
       total_available_quantity, 
       avg_supply_cost, 
       part_names_list
FROM AggregatedSupplierData
ORDER BY avg_supply_cost DESC
LIMIT 10;
