WITH RECURSIVE MovieHierarchy AS (
    -- CTE to recursively find all movies related to a specific movie (for demonstration purposes, let's start from movie_id 1)
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.id = 1

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM title m
    INNER JOIN movie_link ml ON ml.linked_movie_id = m.id
    INNER JOIN MovieHierarchy h ON h.movie_id = ml.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(c.id) AS role_count,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(c.id) DESC) AS actor_rank,
    COALESCE(ca.kind, 'Unknown') AS cast_type
FROM aka_name AS a
JOIN cast_info AS c ON a.person_id = c.person_id
JOIN aka_title AS t ON c.movie_id = t.movie_id
LEFT JOIN movie_keyword AS mk ON t.movie_id = mk.movie_id
LEFT JOIN keyword AS k ON mk.keyword_id = k.id
LEFT JOIN comp_cast_type AS ca ON c.role_id = ca.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND (t.kind_id = 1 OR t.kind_id IS NULL)  -- Only feature films or NULL 
GROUP BY 
    a.id, t.id, ca.kind
HAVING 
    COUNT(c.id) > 1      -- Only actors who played in more than one role
    AND a.name IS NOT NULL
ORDER BY 
    actor_rank, movie_title;

-- Additional outputs can be adjusted with necessary JOINs to extract further required information e.g. company names or more detailed movie info.

This query includes:

- A **recursive CTE** to build a hierarchy of movies linked through `movie_link`.
- A **COUNT** to aggregate roles each actor has played.
- **ARRAY_AGG** to collect distinct keywords associated with each movie.
- **ROW_NUMBER** window function to rank actors based on the number of roles.
- **LEFT JOIN** to handle NULL values when linking to cast types and keywords.
- A **HAVING** clause to filter actors who have played more than one role.
- A variety of predicates for filtering on title attributes and roles.
