WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mv.movie_id,
    mv.title,
    mv.production_year,
    COUNT(DISTINCT c.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS award_count,
    AVG(CASE WHEN kw.keyword IS NOT NULL THEN 1 ELSE NULL END) AS keyword_density,
    MAX(mk.keyword IS NOT NULL) AS has_keywords
FROM 
    MovieHierarchy mv
LEFT JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON ak.person_id = c.person_id
LEFT JOIN 
    movie_info mi ON mv.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mv.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    mv.level <= 3 
    AND (mv.production_year BETWEEN 2000 AND 2023)
GROUP BY 
    mv.movie_id, mv.title, mv.production_year
HAVING 
    AVG(c.nr_order) > 5 
ORDER BY 
    cast_count DESC, mv.production_year DESC
LIMIT 100;
