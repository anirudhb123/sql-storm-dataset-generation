WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        mt.production_year,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.level + 1 AS level,
        at.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mv.movie_title,
    mv.production_year,
    COUNT(c.id) AS total_cast,
    ARRAY_AGG(DISTINCT p.name) AS actors,
    MAX(CASE WHEN u.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN u.info END) AS rating,
    MIN(CASE WHEN u.info_type_id = (SELECT id FROM info_type WHERE info = 'runtime') THEN u.info END) AS runtime,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY COUNT(c.id) DESC) AS rank,
    CAST(SUM(CASE WHEN c.nr_order IS NULL THEN 1 ELSE 0 END) AS INTEGER) AS NullRoleCount
FROM 
    MovieHierarchy mv
LEFT JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON c.movie_id = mv.movie_id
LEFT JOIN 
    aka_name p ON p.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mv.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_info u ON mv.movie_id = u.movie_id
WHERE 
    mv.production_year > 1980
GROUP BY 
    mv.movie_id, mv.movie_title, mv.production_year
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    mv.production_year DESC, total_cast DESC;
