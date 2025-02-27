WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000 -- Start with movies after the year 2000

    UNION ALL

    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        level + 1
    FROM 
        MovieCTE m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.movie_id
    JOIN 
        aka_title t ON t.id = ml.movie_id
    WHERE 
        m.level < 3 -- Limit depth of recursion to 3
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS number_of_movies,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    SUM(CASE WHEN t.production_year < 2010 THEN 1 ELSE 0 END) AS movies_before_2010,
    AVG(p.info::FLOAT) FILTER (WHERE p.info_type_id = 1) AS avg_age_of_actors, -- Assuming info_type_id=1 denotes age

    CASE 
        WHEN COUNT(DISTINCT c.movie_id) = 0 THEN 'No Movies'
        ELSE 'Active Actor'
    END AS actor_status

FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieCTE m ON c.movie_id = m.movie_id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
LEFT JOIN 
    info_type it ON p.info_type_id = it.id
LEFT JOIN 
    aka_title t ON m.movie_id = t.id
WHERE 
    a.name IS NOT NULL 
    AND a.id IS NOT NULL 
GROUP BY 
    a.name
ORDER BY 
    number_of_movies DESC;

**Explanation:**

- **Common Table Expression (CTE)**: A recursive CTE is used to determine a hierarchy of movies starting from those produced after the year 2000. The recursion allows fetching linked movies to a depth limit of 3.

- **Aggregations**: The main query aggregates data by actor, counting distinct movies featuring the actor, and listing other movie titles in which the actor appears.

- **Filtering with Aggregation**: It calculates the number of movies released before 2010 and computes the average age of actors from their `person_info`, assuming info_type_id 1 corresponds to age-related data.

- **Conditional Expressions**: A CASE statement determines the actor's status based on the number of movies they've acted in.

- **Joins**: LEFT JOINs handle optional relationships, ensuring that results include actors who may not have any associated `person_info`. 

- **String Aggregation**: It creates a comma-separated list of movie titles.

- **NULL Handling**: The WHERE clause checks for NULL values, ensuring only valid actors are included in the results.

This query can be used for performance benchmarking by analyzing its execution time with this complex structure against different dataset sizes and optimization conditions.
