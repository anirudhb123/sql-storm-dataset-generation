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
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    INNER JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT ch.subject_id) AS total_customers,
    AVG(CASE 
        WHEN ch.status_id IS NULL THEN 0 
        ELSE 1 
    END) AS avg_status,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    ARRAY_AGG(DISTINCT mt.title) AS linked_movies,
    RANK() OVER (PARTITION BY mk.keyword ORDER BY COUNT(DISTINCT ch.subject_id) DESC) AS keyword_rank
FROM 
    movie_keyword mk
LEFT JOIN 
    complete_cast ch ON mk.movie_id = ch.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = ch.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = mk.movie_id
WHERE 
    mk.movie_id IS NOT NULL
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT ch.subject_id) > 5
ORDER BY 
    keyword_rank;
