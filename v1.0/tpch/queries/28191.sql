WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS supply_info,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_name ORDER BY ps.ps_supplycost DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        supplier_name,
        part_name,
        supply_info,
        available_quantity,
        supply_cost
    FROM SupplierParts
    WHERE available_quantity > 100 
      AND supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    supplier_name,
    STRING_AGG(part_name, ', ') AS part_names,
    COUNT(*) AS part_count,
    STRING_AGG(CONCAT(part_name, ' ($', supply_cost, ')'), '; ') AS detailed_part_info
FROM FilteredSuppliers
GROUP BY supplier_name
ORDER BY part_count DESC, supplier_name;
