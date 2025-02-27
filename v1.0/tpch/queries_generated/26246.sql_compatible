
WITH StringProcessing AS (
    SELECT 
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS name_upper,
        LOWER(p.p_name) AS name_lower,
        CONCAT('Part: ', p.p_name, ', Type: ', p.p_type) AS name_type_combo,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost > 100.00)
)

SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    STRING_AGG(DISTINCT sp.name_upper, ', ') AS uppercased_names,
    AVG(sp.name_length) AS avg_name_length,
    MAX(sp.short_comment) AS max_short_comment
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    StringProcessing sp ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name = sp.p_name) LIMIT 1)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT sp.name_upper) > 5
ORDER BY 
    avg_name_length DESC;
