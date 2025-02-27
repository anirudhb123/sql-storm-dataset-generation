WITH RECURSIVE MovieNetwork AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        mk.linked_movie_id,
        lt.title,
        lt.production_year,
        mn.depth + 1
    FROM 
        MovieNetwork mn
    JOIN 
        movie_link mk ON mn.movie_id = mk.movie_id
    JOIN 
        aka_title lt ON mk.linked_movie_id = lt.id
    WHERE 
        lt.production_year > mn.production_year
)

SELECT 
    p.name AS actor_name,
    t.title AS movie_title,
    t.production_year AS movie_year,
    COUNT(c.role_id) AS role_count,
    AVG(i.imdb_id) AS avg_imdb_id,
    ARRAY_AGG(DISTINCT kw.keyword) AS associated_keywords,
    ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY COUNT(c.role_id) DESC) AS rank
FROM 
    aka_name p
JOIN 
    cast_info c ON p.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info ip ON p.person_id = ip.person_id AND ip.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards') 
LEFT JOIN 
    MovieNetwork mn ON mn.movie_id = t.id
WHERE 
    c.note IS NULL 
    AND (ip.info IS NULL OR ip.info != 'N/A')
GROUP BY 
    p.id, t.id, mn.depth
HAVING 
    COUNT(c.role_id) > 2
ORDER BY 
    rank, p.name, movie_year DESC;

### Query Explanation:
1. **CTE (Common Table Expression)**: A recursive CTE named `MovieNetwork` is created to establish a hierarchy of movies linked to each other through the `movie_link` table, focusing on movies produced after 2000.
2. **Main Query**: 
   - It selects actor names, movie titles, and their production years.
   - It counts roles associated with each actor and computes the average IMDB IDs from the `movie_info` table.
   - It aggregates distinct keywords associated with the movies.
   - Implements a window function to rank actors based on the count of roles.
3. **Joins**: Various outer joins to combine information from multiple tables. Checks for `NULL` in notes and specific conditions for person info.
4. **Group By & Having**: Ensures that only actors with more than two roles are returned.
5. **Ordering**: Final results are ordered by the rank of actors and their names.
