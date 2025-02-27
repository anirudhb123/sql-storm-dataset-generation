WITH RECURSIVE movie_hierarchy AS (
    SELECT m.movie_id, m.title, 1 AS level
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- Base level: Movies

    UNION ALL

    SELECT m.movie_id, m.title, mh.level + 1 AS level
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.movie_id
)

SELECT 
    p.name AS actor_name,
    AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes_ratio,
    COUNT(DISTINCT m.movie_id) AS total_movies,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    COUNT(DISTINCT k.keyword) AS total_keywords,
    EXTRACT(YEAR FROM CURRENT_DATE) - MIN(m.production_year) AS years_since_first_movie,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY m.production_year) AS median_production_year
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    p.name IS NOT NULL
    AND (m.production_year BETWEEN 1990 AND 2023)
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT m.movie_id) > 5
ORDER BY 
    years_since_first_movie DESC, 
    total_movies DESC;

This SQL query:

1. Uses a recursive CTE named `movie_hierarchy` to build a hierarchy of movies, starting with a specific movie type (in this case, movies).
2. Joins various tables (`cast_info`, `aka_name`, `aka_title`, `movie_keyword`, `keyword`) to gather data about actors, their associated movies, and keywords related to those movies.
3. Calculates several metrics, including:
   - The ratio of movies with notes for each actor.
   - Total movies an actor has appeared in.
   - A concatenated list of movie titles for those movies.
   - The total number of distinct keywords associated with the movies.
   - The number of years since the actor's first recorded movie.
   - The median production year of all movies the actor has appeared in.
4. Filters the results to include only actors who have appeared in more than 5 movies produced between 1990 and 2023.
5. Orders the final result by how long it has been since the actor's first movie and the total number of movies they acted in, both in descending order.
