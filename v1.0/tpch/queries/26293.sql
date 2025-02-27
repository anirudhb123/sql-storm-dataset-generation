WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        SUBSTRING(p.p_comment, 1, 20) AS part_comment_snippet,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(SUBSTRING(s.s_address, 1, 15), '...') AS short_address,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
AggregatedData AS (
    SELECT 
        supplier_name,
        COUNT(part_name) AS part_count,
        SUM(available_quantity) AS total_available_quantity,
        AVG(supply_cost) AS average_supply_cost,
        STRING_AGG(part_comment_snippet, '; ') AS comments
    FROM 
        SupplierParts
    GROUP BY 
        supplier_name
)
SELECT 
    supplier_name,
    part_count,
    total_available_quantity,
    average_supply_cost,
    comments
FROM 
    AggregatedData
WHERE 
    part_count > 5
ORDER BY 
    average_supply_cost DESC;
