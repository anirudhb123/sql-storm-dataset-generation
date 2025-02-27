WITH RECURSIVE CTE_MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        m.id AS root_movie_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        ch.level + 1,
        ch.root_movie_id
    FROM 
        aka_title e
    JOIN 
        aka_title p ON e.episode_of_id = p.id
    JOIN 
        CTE_MovieHierarchy ch ON p.id = ch.movie_id
)

SELECT 
    m.movie_id,
    COUNT(DISTINCT c.person_id) AS cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    AVG(COALESCE(mi.provided_info_count, 0)) AS avg_additional_info,
    SUM(
        CASE 
            WHEN c.note IS NOT NULL THEN 1 
            ELSE 0 
        END
    ) AS note_count,
    ROW_NUMBER() OVER (PARTITION BY m.root_movie_id ORDER BY m.production_year DESC) AS rank_level
FROM 
    CTE_MovieHierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(*) AS provided_info_count
    FROM 
        movie_info GROUP BY movie_id
) mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    m.production_year >= 2000
GROUP BY 
    m.movie_id, m.title, m.production_year, m.root_movie_id
HAVING 
    COUNT(DISTINCT c.person_id) > 0 AND
    SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) > (SELECT COUNT(*) FROM cast_info) / 10
ORDER BY 
    rank_level, m.production_year DESC;
