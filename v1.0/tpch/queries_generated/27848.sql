WITH StringAgg AS (
    SELECT 
        n.n_name AS nation_name,
        STRING_AGG(CONCAT(p.p_name, ' (', s.s_name, ')'), ', ') AS part_supplier_list,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        nation n 
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
    WHERE 
        LENGTH(p.p_name) > 15
    GROUP BY 
        n.n_name
), TotalCount AS (
    SELECT 
        COUNT(DISTINCT p.p_partkey) AS total_part_count
    FROM 
        part p 
    WHERE 
        LENGTH(p.p_name) > 15
)
SELECT
    s.nation_name,
    s.part_supplier_list,
    s.part_count,
    t.total_part_count,
    ROUND((s.part_count * 100.0 / t.total_part_count), 2) AS percentage_of_total
FROM 
    StringAgg s,
    TotalCount t
WHERE 
    s.part_count > 0
ORDER BY 
    percentage_of_total DESC;
