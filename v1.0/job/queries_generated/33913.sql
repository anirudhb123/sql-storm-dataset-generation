WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS total_roles,
    AVG(COALESCE(pi.info, '')::int) AS average_rating,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS row_pos
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON cc.movie_id = m.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    company_name cn ON cn.imdb_id IN (
        SELECT mc.company_id FROM movie_companies mc WHERE mc.movie_id = m.movie_id
    )
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    person_info pi ON pi.person_id = c.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'age')
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 3 
    AND AVG(COALESCE(pi.info, '')::int) > 5 
ORDER BY 
    COUNT(DISTINCT c.person_id) DESC,
    m.production_year DESC;
