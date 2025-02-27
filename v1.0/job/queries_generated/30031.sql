WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.id AS actor_id,
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    ci.note AS role_note,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    RANK() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS rank_by_year
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
WHERE 
    ci.nr_order IS NOT NULL
    AND (ci.note IS NULL OR ci.note != 'Cameo')
GROUP BY 
    a.id, a.name, m.title, m.production_year, ci.note
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 5
ORDER BY 
    keyword_count DESC, 
    rank_by_year ASC;
