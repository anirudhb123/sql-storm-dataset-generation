WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        CONCAT(s.s_address, ', ', s.s_phone) AS supplier_details,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        SUBSTRING(p.p_comment, 1, 20) AS short_comment,
        CASE 
            WHEN ps.ps_availqty < 100 THEN 'Low Stock'
            WHEN ps.ps_availqty BETWEEN 100 AND 500 THEN 'Medium Stock'
            ELSE 'High Stock'
        END AS stock_status
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
SupplierPartAggregates AS (
    SELECT 
        supplier_name,
        COUNT(part_name) AS total_parts,
        SUM(available_quantity) AS total_available_qty,
        AVG(supply_cost) AS avg_supply_cost,
        STRING_AGG(DISTINCT stock_status, ', ') AS stock_statuses
    FROM 
        SupplierPartDetails
    GROUP BY 
        supplier_name
)
SELECT 
    supplier_name,
    total_parts,
    total_available_qty,
    avg_supply_cost,
    stock_statuses,
    CASE 
        WHEN total_available_qty > 1000 THEN 'Bulk Supplier'
        WHEN total_parts > 5 THEN 'Regular Supplier'
        ELSE 'Occasional Supplier'
    END AS supplier_type
FROM 
    SupplierPartAggregates
ORDER BY 
    total_available_qty DESC, 
    total_parts DESC;
