WITH RecursiveStringAggregation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        GROUP_CONCAT(DISTINCT p.p_name ORDER BY p.p_name SEPARATOR ', ') AS part_names,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        LENGTH(part_names) AS name_length,
        part_count
    FROM 
        RecursiveStringAggregation s
    WHERE 
        part_count > 5 AND
        name_length > 200
)
SELECT 
    fs.s_suppkey, 
    fs.s_name, 
    fs.part_count, 
    REPLACE(part_names, ', ', ' # ') AS transformed_parts
FROM 
    FilteredSuppliers fs
ORDER BY 
    fs.part_count DESC, 
    fs.s_name ASC;
