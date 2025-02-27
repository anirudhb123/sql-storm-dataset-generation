WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        mt.production_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000  -- Filter for more recent movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        a.title AS movie_title,
        mh.level + 1,
        a.production_year
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    th.movie_title,
    th.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords,
    SUM(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS num_roles,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE NULL END) AS avg_order,
    MAX(th.production_year) OVER (PARTITION BY a.name) AS latest_year,
    NULLIF(MIN(th.production_year) OVER (PARTITION BY a.name), 2020) AS min_year_after_2020
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieHierarchy th ON c.movie_id = th.movie_id
LEFT JOIN 
    movie_keyword mk ON th.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, th.movie_title, th.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY 
    keyword_count DESC, latest_year DESC;
