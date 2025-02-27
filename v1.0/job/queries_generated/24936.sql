WITH RECURSIVE Film_Sequence AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS seq_level,
        CAST(m.title AS VARCHAR(255)) AS full_path
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        CONCAT(c.title, ' > ', m.title) AS title,
        m.production_year,
        fs.seq_level + 1,
        CONCAT(fs.full_path, ' > ', m.title)
    FROM 
        aka_title AS m
    JOIN 
        movie_link AS ml ON ml.movie_id = m.id
    JOIN 
        aka_title AS c ON c.id = ml.linked_movie_id
    JOIN 
        Film_Sequence AS fs ON fs.movie_id = c.id
    WHERE 
        fs.seq_level < 5
)

SELECT
    fs.movie_id,
    fs.title,
    fs.production_year,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY fs.movie_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    CASE 
        WHEN MIN(r.role) IS NULL THEN 'Unknown Role'
        ELSE MIN(r.role)
    END AS primary_role,
    CASE 
        WHEN MAX(mg.name_pcode_nf) IS NULL THEN 'N/A'
        ELSE MAX(mg.name_pcode_nf)
    END AS pcode_nf,
    CONCAT(
        COALESCE(NULLIF(mg.name_pcode_cf, ''), 'No Code'),
        ' - Year: ',
        COALESCE(CAST(fs.production_year AS VARCHAR), 'Unknown')
    ) AS detailed_info
FROM 
    Film_Sequence AS fs
LEFT JOIN 
    complete_cast AS cc ON cc.movie_id = fs.movie_id
LEFT JOIN 
    cast_info AS c ON c.id = cc.subject_id
LEFT JOIN 
    aka_name AS a ON a.person_id = c.person_id
LEFT JOIN 
    role_type AS r ON r.id = c.role_id
LEFT JOIN 
    name AS mg ON mg.id = a.id
WHERE 
    fs.seq_level < 4
GROUP BY
    fs.movie_id, fs.title, fs.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 2
ORDER BY 
    fs.production_year DESC, total_cast DESC;

-- The query involves a recursive CTE to generate a film hierarchy, outer joins to gather related actor and role information,
-- and several constructs like aggregation, case statements, and string manipulations to provide detailed output.
