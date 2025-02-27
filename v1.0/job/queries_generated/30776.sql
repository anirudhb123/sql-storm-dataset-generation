WITH RECURSIVE related_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        mm.id AS movie_id,
        mm.title,
        mm.production_year,
        rm.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mm ON ml.linked_movie_id = mm.id
    JOIN 
        related_movies rm ON ml.movie_id = rm.movie_id
    WHERE 
        mm.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    a.name AS actor_name,
    r.movie_id,
    r.title AS related_movie_title,
    r.production_year,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    AVG(CASE 
            WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
            THEN CAST(pi.info AS FLOAT)
            ELSE NULL 
        END) AS average_rating,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    related_movies r
LEFT JOIN 
    cast_info ci ON r.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info pi ON r.movie_id = pi.movie_id
WHERE 
    r.level = 1 
GROUP BY 
    a.name, r.movie_id, r.title, r.production_year
ORDER BY 
    average_rating DESC NULLS LAST
LIMIT 10;

This SQL query performs the following operations:

1. **Recursive CTE `related_movies`:** It builds a hierarchy of movies that are linked to each other through `movie_link` while filtering only for movies.
   
2. **Main Select Statement:** This pulls together information from various tables:
   - It gets the actor names from the `aka_name` table.
   - It counts the total number of actors involved in each `related_movies` entry.
   - It computes the average rating (if available) for each movie by checking against `info_type`.
   - It aggregates keywords associated with each movie using `STRING_AGG`.

3. **LEFT JOINs and NULL logic:** Several joins are made to gather all relevant data while allowing `NULL` values to propagate where data may be missing (e.g., movies without keywords).

4. **Complex Aggregations:** The use of `COUNT`, `AVG`, and `STRING_AGG` makes it possible to extract insightful summaries for the top related movies based on certain criteria.

5. **Ordering and Limiting:** Finally, the results are ordered by average rating while handling `NULLs`, and limited to the top 10 results.

This query can help benchmark performance for complex queries involving multiple table joins, aggregations, and recursive logic.
