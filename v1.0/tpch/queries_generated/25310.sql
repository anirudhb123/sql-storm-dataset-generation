WITH StringManipulations AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_mfgr) AS lower_mfgr,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_container, 'box', 'container') AS modified_container,
        SUBSTRING(p.p_type FROM 1 FOR 10) AS type_substring
    FROM 
        part p
), AggregatedData AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(CAST(SUBSTRING(s.s_comment FROM 1 FOR 20) AS TEXT)) AS excerpt_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    MAX(a.unique_parts) AS max_unique_parts,
    LISTAGG(CONCAT(a.s_name, ': ', a.excerpt_comment), '; ') WITHIN GROUP (ORDER BY a.s_name) AS supplier_comments
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    AggregatedData a ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_name = a.s_name LIMIT 1)
GROUP BY 
    r.r_name
ORDER BY 
    region_name;
