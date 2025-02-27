WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming 1 is for movies

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title,
    m.production_year,
    a.name AS actor_name,
    p.info AS person_info,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
    SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS ranking
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id AND p.info_type_id = 1  -- Assuming 1 is for some specific info type
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
GROUP BY 
    m.movie_id, a.name, p.info
HAVING 
    COUNT(DISTINCT kc.keyword) > 2 -- Filter for movies with more than 2 unique keywords
ORDER BY 
    ranking, m.production_year DESC;

This query constructs a recursive CTE to retrieve a hierarchy of movies, including linked movies. It then joins various relevant tables to fetch actor names, person information, keyword counts, and additional statistical metrics. The final output is grouped by movie while applying filtering logic through the `HAVING` clause to ensure only movies with more than a specified number of keywords are included. Additionally, it incorporates window functions to rank movies per production year.
