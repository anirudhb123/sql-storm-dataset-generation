
WITH String_Stats AS (
    SELECT 
        p.p_name AS part_name,
        LENGTH(p.p_name) AS name_length,
        COUNT(*) OVER (PARTITION BY LENGTH(p.p_name)) AS count_by_length,
        LEFT(p.p_comment, 10) AS comment_preview,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_name, p.p_comment
),
Group_Stats AS (
    SELECT 
        name_length,
        SUM(count_by_length) AS total_parts,
        LISTAGG(DISTINCT part_name, ', ') WITHIN GROUP (ORDER BY part_name) AS part_names,
        LISTAGG(DISTINCT comment_preview, ', ') WITHIN GROUP (ORDER BY comment_preview) AS comments
    FROM 
        String_Stats
    GROUP BY 
        name_length
)
SELECT 
    gs.name_length,
    gs.total_parts,
    gs.part_names,
    gs.comments
FROM 
    Group_Stats gs
WHERE 
    gs.total_parts > 1
ORDER BY 
    gs.name_length DESC;
