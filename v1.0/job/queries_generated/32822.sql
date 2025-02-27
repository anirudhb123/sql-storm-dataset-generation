WITH RECURSIVE MoviePaths AS (
    -- Base case: Get the movies and their direct linked movies
    SELECT
        m.movie_id AS movie_id,
        m.linked_movie_id,
        1 AS depth
    FROM
        movie_link m
    WHERE
        m.link_type_id = (SELECT id FROM link_type WHERE link = 'related to')  -- adjust the link type as necessary

    UNION ALL

    -- Recursive case: Find additional linked movies
    SELECT
        mp.movie_id,
        ml.linked_movie_id,
        mp.depth + 1
    FROM
        MoviePaths mp
    JOIN
        movie_link ml ON mp.linked_movie_id = ml.movie_id
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related to')
)

SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COALESCE(c.kind, 'Unknown') AS company_type,
    COUNT(DISTINCT mp.linked_movie_id) AS related_movie_count,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS movie_rank
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN
    movie_companies mc ON mc.movie_id = t.movie_id
LEFT JOIN
    company_type c ON mc.company_type_id = c.id
LEFT JOIN
    MoviePaths mp ON mp.movie_id = t.movie_id
WHERE
    t.production_year IS NOT NULL 
    AND a.name IS NOT NULL 
    AND EXISTS (
        SELECT 1 
        FROM movie_keyword mk 
        WHERE mk.movie_id = t.movie_id 
        AND mk.keyword_id IN (
            SELECT id FROM keyword WHERE keyword IN ('Drama', 'Thriller')  -- Example keywords
        )
    )
GROUP BY
    a.name,
    t.title,
    t.production_year,
    c.kind
HAVING
    COUNT(DISTINCT mp.linked_movie_id) > 0
ORDER BY
    a.name,
    t.production_year DESC;

This SQL query achieves the following:
1. Uses a recursive CTE (`MoviePaths`) to fetch related movies for each movie linked through the `movie_link` table.
2. Joins several tables to grab actor names, movie titles, production years, and company types.
3. Includes a correlated subquery to filter movies based on specified keywords.
4. Utilizes the `COALESCE` function to handle potential NULL values for company types.
5. Applies a window function to rank movies for each actor based on production year.
6. Groups results by actor and movie details, ensuring that only movies with related links are counted and displayed.

This query can be valuable for performance benchmarking due to its complexity and use of multiple SQL constructs.
