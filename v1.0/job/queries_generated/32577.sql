WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        h.level + 1
    FROM 
        MovieHierarchy AS h
    JOIN 
        movie_link AS ml ON ml.linked_movie_id = h.movie_id
    JOIN 
        aka_title AS t ON t.id = ml.movie_id
)

SELECT
    DISTINCT a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count,
    STRING_AGG(DISTINCT kw.keyword, ', ' ORDER BY kw.keyword) AS keywords,
    (SELECT COUNT(*)
     FROM movie_info mi
     WHERE mi.movie_id = t.id 
     AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')) AS budget_info_count
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
LEFT JOIN 
    MovieHierarchy AS mh ON mh.movie_id = t.id
WHERE 
    (a.name IS NOT NULL OR a.name_pcode_cf IS NOT NULL)
    AND (t.production_year BETWEEN 2000 AND 2023)
    AND (a.id IS NOT NULL)
ORDER BY 
    actor_name, t.production_year DESC
LIMIT 100;
