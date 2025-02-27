WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.movie_id,
        ca.person_id,
        1 AS hierarchy_level
    FROM
        cast_info AS c
    JOIN
        aka_name AS ca ON c.person_id = ca.person_id
    WHERE
        ca.name LIKE 'A%'  -- Filter for actors with names starting with 'A'

    UNION ALL

    SELECT
        m.movie_id,
        c.person_id,
        ah.hierarchy_level + 1
    FROM
        cast_info AS c
    JOIN
        ActorHierarchy AS ah ON c.movie_id = ah.movie_id
    JOIN
        movie_link AS ml ON c.movie_id = ml.movie_id
    JOIN
        title AS m ON ml.linked_movie_id = m.id 
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c2.person_id) AS co_stars,
    AVG(mi.info::numeric) AS avg_rating,
    MAX(mi.info) AS best_review,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    ActorHierarchy AS ah
JOIN 
    aka_name AS a ON ah.person_id = a.person_id
JOIN 
    aka_title AS at ON ah.movie_id = at.movie_id
JOIN 
    title AS t ON at.movie_id = t.id
LEFT JOIN 
    cast_info AS c2 ON c2.movie_id = t.id
LEFT JOIN 
    movie_info AS mi ON mi.movie_id = t.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year >= 2000 
    AND (t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%') 
    OR EXISTS (SELECT 1 FROM movie_companies mc WHERE mc.movie_id = t.id AND mc.company_id IS NOT NULL))
GROUP BY 
    a.name, t.id
ORDER BY 
    AVG(mi.info::numeric) DESC, co_stars DESC
LIMIT 10;

### Explanation of Query Components:
- **WITH RECURSIVE**: Creating a recursive CTE to build a hierarchy of movies starring actors whose names start with 'A'.
- **JOINs**: Multiple joins to bring in data from related tables (e.g., cast_info, title, movie_info, etc.).
- **COUNT(DISTINCT)**: Count distinct co-stars in movies for each actor.
- **AVG() and MAX()**: Calculate average movie ratings and find the best review for each movie.
- **STRING_AGG()**: Aggregate keywords associated with each movie into a comma-separated string.
- **COMPLICATED PREDICATES**: Filters to include only movies from the year 2000 onwards, and either of certain genres or produced by known companies.
- **ORDER BY**: Sort results primarily by average rating and secondarily by the number of co-stars.
- **LIMIT**: Restricts the output to the top 10 results.
