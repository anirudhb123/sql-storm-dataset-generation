WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS supply_info,
        LENGTH(CONCAT(s.s_name, ' supplies ', p.p_name)) AS supply_info_length
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregatedSupply AS (
    SELECT 
        supplier_name,
        COUNT(part_name) AS total_parts,
        SUM(available_quantity) AS total_availability,
        AVG(supply_cost) AS average_supply_cost,
        STRING_AGG(part_name, ', ') AS part_names,
        MAX(supply_info_length) AS max_supply_info_length
    FROM 
        SupplierParts
    GROUP BY 
        supplier_name
)
SELECT 
    supplier_name,
    total_parts,
    total_availability,
    average_supply_cost,
    part_names,
    max_supply_info_length
FROM 
    AggregatedSupply
WHERE 
    total_availability > 10
ORDER BY 
    total_parts DESC;
