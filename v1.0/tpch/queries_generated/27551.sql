WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with a price of ', ps.ps_supplycost) AS description
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregatedData AS (
    SELECT 
        supplier_name,
        COUNT(part_name) AS total_parts,
        SUM(available_quantity) AS total_available_quantity,
        AVG(supply_cost) AS average_supply_cost,
        STRING_AGG(description, '; ') AS supplier_descriptions
    FROM 
        SupplierParts
    GROUP BY 
        supplier_name
)
SELECT 
    supplier_name,
    total_parts,
    total_available_quantity,
    average_supply_cost,
    supplier_descriptions
FROM 
    AggregatedData
WHERE 
    total_available_quantity > 100
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
