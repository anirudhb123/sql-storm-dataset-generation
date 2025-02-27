WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2021  -- Starting point for hierarchy (for filtering purposes)

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS total_movies,
    AVG(m.production_year - ch.year_of_birth) AS avg_age_at_release,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY m.movie_id ORDER BY COUNT(DISTINCT ct.role_id) DESC) AS role_rank
FROM 
    aka_name a
JOIN 
    cast_info ch ON a.person_id = ch.person_id
JOIN 
    movie_hierarchy m ON ch.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    role_type ct ON ch.role_id = ct.id
JOIN 
    person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = 1  -- Assuming 1 is the ID for year_of_birth
WHERE 
    a.name IS NOT NULL 
    AND m.production_year IS NOT NULL
GROUP BY 
    a.name, m.movie_id
HAVING 
    COUNT(DISTINCT ch.movie_id) > 5
ORDER BY 
    total_movies DESC;

This SQL query utilizes various constructs such as a recursive CTE to create a movie hierarchy, joins with multiple tables to gather relevant data, aggregates for counting and averaging, string aggregation for keywords, and ranks the actors based on their roles in the movie. It also includes conditions filtering actors who have been in more than a specified number of movies, showcasing complex and interesting SQL features.
