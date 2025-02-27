WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_type AS part_type,
        COUNT(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost,
        STRING_AGG(DISTINCT p.p_comment, '; ') AS combined_comments
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name, p.p_type
),
PartSummary AS (
    SELECT 
        part_name,
        part_type,
        MAX(total_available) AS max_available,
        MIN(total_available) AS min_available,
        AVG(total_available) AS avg_available,
        SUM(total_cost) AS total_cost,
        COUNT(*) AS supplier_count
    FROM 
        SupplierParts
    GROUP BY 
        part_name, part_type
)
SELECT 
    ps.part_name,
    ps.part_type,
    ps.max_available,
    ps.min_available,
    ps.avg_available,
    ps.total_cost,
    ps.supplier_count,
    CONCAT('Type: ', ps.part_type, ' | Availability: ', ps.max_available, ' (max), ', ps.min_available, ' (min), ', ROUND(ps.avg_available, 2), ' (avg)') AS availability_summary
FROM 
    PartSummary ps
WHERE 
    ps.supplier_count > 1
ORDER BY 
    ps.total_cost DESC, ps.part_name;
