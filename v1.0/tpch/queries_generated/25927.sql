WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with a cost of ', 
               TO_CHAR(ps.ps_supplycost, 'FM$999,999.00'), 
               ' and availability of ', ps.ps_availqty, ' units.') AS detailed_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredDetails AS (
    SELECT 
        supplier_name,
        part_name,
        available_quantity,
        supply_cost,
        detailed_info
    FROM 
        SupplierPartDetails
    WHERE 
        available_quantity > 100
        AND supply_cost < 50.00
)
SELECT 
    supplier_name,
    COUNT(part_name) AS number_of_parts,
    STRING_AGG(detailed_info, '; ') AS aggregated_info
FROM 
    FilteredDetails
GROUP BY 
    supplier_name
ORDER BY 
    number_of_parts DESC;
