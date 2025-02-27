WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_brand AS part_brand,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        p.p_comment AS part_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        supplier_name,
        part_name,
        part_brand,
        available_quantity,
        supply_cost,
        part_comment,
        CONCAT('Supplier: ', supplier_name, ', Part: ', part_name, ', Brand: ', part_brand) AS supplier_part_info
    FROM 
        SupplierParts
    WHERE 
        available_quantity > 50 AND
        supply_cost < 100.00
),
AggregatedResults AS (
    SELECT 
        part_brand,
        COUNT(*) AS total_suppliers,
        SUM(available_quantity) AS total_available_quantity,
        AVG(supply_cost) AS average_supply_cost,
        STRING_AGG(supplier_part_info, '; ') AS supplier_details
    FROM 
        FilteredSuppliers
    GROUP BY 
        part_brand
)
SELECT 
    part_brand,
    total_suppliers,
    total_available_quantity,
    average_supply_cost,
    supplier_details
FROM 
    AggregatedResults
ORDER BY 
    total_suppliers DESC, 
    average_supply_cost ASC;
