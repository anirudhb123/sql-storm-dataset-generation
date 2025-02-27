WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mt.kind AS movie_type,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        kind_type mt ON m.kind_id = mt.id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mt.kind AS movie_type,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    INNER JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        kind_type mt ON m.kind_id = mt.id
)
SELECT 
    mv.movie_id,
    mv.title,
    mv.production_year,
    mv.movie_type,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    AVG(CASE WHEN mv.production_year < 2010 THEN 1 ELSE NULL END) AS pre_2010_count,
    SUM(CASE 
            WHEN ci.note IS NULL THEN 1 
            ELSE 0 
        END) AS null_notes_count
FROM 
    MovieHierarchy mv
LEFT JOIN 
    cast_info ci ON mv.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    mv.movie_type IS NOT NULL
GROUP BY 
    mv.movie_id, mv.title, mv.production_year, mv.movie_type
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    total_cast DESC, mv.production_year DESC;
