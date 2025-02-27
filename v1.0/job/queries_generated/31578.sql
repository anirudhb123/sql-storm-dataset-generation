WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL
    
    SELECT 
        mk.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link mk ON mk.movie_id = mh.movie_id
    JOIN 
        aka_title t ON mk.linked_movie_id = t.id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS unknown_roles,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS role_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Box Office'
    )
WHERE 
    (m.production_year BETWEEN 2000 AND 2023) 
    AND (mi.info IS NOT NULL OR (mi.info IS NULL AND m.title LIKE '%Untitled%'))
    AND (a.name IS NOT NULL AND a.name <> '')
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.role_id) > 1
ORDER BY 
    total_cast DESC, m.production_year DESC;
This SQL query showcases several advanced constructs:

- A recursive Common Table Expression (CTE) called `MovieHierarchy` to build a hierarchy of movies linked to each other.
- Multiple joins that involve outer joins and left joins for optional information matching.
- Window functions, like `ROW_NUMBER()`, to provide a ranking of movie roles per actor.
- Compound conditions that filter on the movie's production year, information presence, and actor's name.
- Grouping and aggregation to count distinct roles and unknown roles.
- Usage of a subquery to dynamically select an info_type based on a condition.

This type of query could be useful for performance benchmarking to evaluate how the SQL engine manages multiple joins, aggregations, and recursive logic.
