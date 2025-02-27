WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        NULL::integer AS parent_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        m.title, 
        m.production_year, 
        mh.movie_id, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    CONCAT(a.name, ' (', a.surname_pcode, ')') AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS total_roles,
    COUNT(CASE WHEN ci.note IS NOT NULL THEN 1 END) AS noted_roles,
    COALESCE(SUM(ki.keyword_count), 0) AS total_keywords,
    ROW_NUMBER() OVER(PARTITION BY mt.id ORDER BY COUNT(ci.id) DESC) AS role_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    (SELECT 
         mk.movie_id, 
         COUNT(mk.keyword_id) AS keyword_count
     FROM 
         movie_keyword mk
     GROUP BY 
         mk.movie_id) ki ON mt.id = ki.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    mt.production_year >= 2000 
    AND (a.name IS NOT NULL AND a.name <> '')
    AND (ci.nr_order IS NULL OR ci.nr_order < 5)
GROUP BY 
    a.name, 
    a.surname_pcode, 
    mt.title, 
    mt.production_year
HAVING 
    COUNT(ci.id) > 0
ORDER BY 
    total_roles DESC, 
    movie_title ASC
LIMIT 50;
