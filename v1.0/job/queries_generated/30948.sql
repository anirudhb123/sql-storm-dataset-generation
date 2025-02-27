WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.role_id) AS distinct_roles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(NULLIF(c.name, ''), 'Unknown Role') AS role_desc
FROM 
    cast_info AS c
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy AS mh ON t.id = mh.movie_id
WHERE 
    t.production_year >= 2000 
    AND t.production_year <= 2023
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.name
ORDER BY 
    COUNT(DISTINCT c.role_id) DESC, t.production_year DESC;

### Explanation:
1. **Recursive CTE (Common Table Expression):** Generates a hierarchy of movies linked to each other, allowing for exploration of linked movies in a structured way.
2. **Main SELECT Clause:** Retrieves actor names, movie titles, production years, distinct roles they have played, and aggregates keywords associated with respective movies.
3. **LEFT JOINs:** Used to gather additional data about keywords and links to ensure no data is missed.
4. **NULL Logic:** Uses `COALESCE` and `NULLIF` to handle potential empty strings in role descriptions by replacing them with 'Unknown Role'.
5. **Filtering Conditions:** Limits movies to those released between 2000 and 2023, inclusive.
6. **GROUP BY and ORDER BY:** Groups results by actor and movie title while ordering primarily by the number of distinct roles, then by production year. 

This query benchmarks performance and showcases various SQL constructs through complex joins and aggregations while displaying a structured output regarding movies and actors.
