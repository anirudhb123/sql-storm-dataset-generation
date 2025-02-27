WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_address, ', ', s.s_phone) AS supplier_contact,
        CONCAT('Part Name: ', p.p_name, ', Available Qty: ', ps.ps_availqty, ', Cost: $', ps.ps_supplycost) AS detailed_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 10
),
AggregatedData AS (
    SELECT 
        supplier_name,
        COUNT(part_name) AS part_count,
        SUM(supply_cost) AS total_supply_cost,
        STRING_AGG(detailed_info, '; ') AS part_details
    FROM 
        SupplierPartDetails
    GROUP BY 
        supplier_name
)
SELECT 
    supplier_name,
    part_count,
    total_supply_cost,
    part_details
FROM 
    AggregatedData
WHERE 
    total_supply_cost > 500
ORDER BY 
    total_supply_cost DESC;
