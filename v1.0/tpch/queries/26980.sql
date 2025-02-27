WITH StringBenchmark AS (
    SELECT 
        p.p_name AS part_name,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        REPLACE(p.p_brand, 'BrandA', 'BrandX') AS modified_brand,
        CONCAT('Supplier: ', s.s_name, ', Price: ', CAST(ps.ps_supplycost AS VARCHAR(20))) AS supplier_info,
        LENGTH(p.p_name) AS name_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        LENGTH(p.p_comment) > 5
),
GroupedResults AS (
    SELECT 
        substr(part_name, 1, 5) AS short_name,
        COUNT(*) AS num_records,
        AVG(name_length) AS avg_length,
        STRING_AGG(modified_brand, ', ') AS brands_list
    FROM 
        StringBenchmark
    GROUP BY 
        short_name
)
SELECT 
    g.short_name,
    g.num_records,
    g.avg_length,
    g.brands_list,
    CASE 
        WHEN g.num_records > 100 THEN 'High Volume'
        WHEN g.num_records > 50 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    GroupedResults g
ORDER BY 
    g.avg_length DESC;
