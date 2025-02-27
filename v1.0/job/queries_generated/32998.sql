WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000 -- Base case: movies after 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        CONCAT(mh.movie_title, ' (Sequel)') AS movie_title,
        mh.production_year + 1,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 5 -- Limit depth to 5 levels
)
SELECT 
    a.title AS original_movie_title,
    a.production_year AS original_production_year,
    a.id AS original_movie_id,
    COALESCE(b.movie_title, 'No Sequel') AS sequel_title,
    b.production_year AS sequel_production_year,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    AVG(CASE WHEN ci.role_id < 3 THEN 1 ELSE NULL END) AS avg_principal_cast,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notations_count,
    STRING_AGG(DISTINCT p.info, ', ') FILTER (WHERE p.info IS NOT NULL) AS person_notes
FROM 
    aka_title a
LEFT JOIN 
    MovieHierarchy b ON a.id = b.movie_id
LEFT JOIN 
    complete_cast cc ON a.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    person_info p ON ci.person_id = p.person_id
GROUP BY 
    a.id, a.title, a.production_year, b.movie_title, b.production_year
ORDER BY 
    original_production_year DESC, original_movie_title;
