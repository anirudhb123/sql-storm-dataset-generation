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
        m.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        h.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy h ON h.movie_id = m.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS num_movies,
    AVG(CASE 
        WHEN m.production_year IS NOT NULL THEN EXTRACT(YEAR FROM CURRENT_DATE) - m.production_year 
        ELSE NULL 
    END) AS avg_movie_age,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    CASE 
        WHEN COALESCE(SUM(mh.level), 0) > 5 THEN 'Many Links'
        ELSE 'Few Links'
    END AS link_category
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title m ON c.movie_id = m.id
WHERE 
    a.name IS NOT NULL
    AND m.production_year > 2000
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 3
ORDER BY 
    num_movies DESC;

This SQL query generates a summary of actors and the movies they have been in, focusing on movies produced after 2000. It uses a recursive Common Table Expression (CTE) called `MovieHierarchy` to explore linked movies, counts how many distinct movies an actor has participated in, calculates the average age of these movies, aggregates movie titles, and categorizes the number of linked movies with a case statement while applying various filters and grouping.
