WITH StringAgg AS (
    SELECT 
        p.p_partkey,
        STRING_AGG(CAST(CONCAT(s.s_name, ' (', p.p_name, ')') AS VARCHAR), ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        sa.supplier_names
    FROM 
        part p
    JOIN 
        StringAgg sa ON p.p_partkey = sa.p_partkey
    WHERE 
        p.p_size > 10 AND 
        LOWER(p.p_brand) LIKE '%brand%' AND
        LENGTH(p.p_comment) > 10
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_brand,
    fp.p_container,
    fp.supplier_names,
    COUNT(DISTINCT n.n_name) AS nation_count
FROM 
    FilteredParts fp
JOIN 
    supplier s ON fp.supplier_names LIKE '%' || s.s_name || '%'
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    fp.p_partkey, fp.p_name, fp.p_brand, fp.p_container, fp.supplier_names
ORDER BY 
    nation_count DESC, fp.p_partkey;
