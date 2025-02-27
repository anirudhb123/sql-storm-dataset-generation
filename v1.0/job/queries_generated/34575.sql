WITH RECURSIVE movie_cast_hierarchy AS (
    SELECT 
        c.movie_id,
        a.person_id,
        a.name AS actor_name,
        ka.title AS movie_title,
        1 AS recursion_level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title ka ON c.movie_id = ka.movie_id
    WHERE 
        ka.production_year > 2000
    
    UNION ALL

    SELECT 
        mc.movie_id,
        a.person_id,
        a.name AS actor_name,
        ka.title AS movie_title,
        mch.recursion_level + 1
    FROM 
        movie_cast_hierarchy mch
    JOIN 
        cast_info mc ON mch.movie_id = mc.movie_id
    JOIN 
        aka_name a ON mc.person_id = a.person_id
    JOIN 
        aka_title ka ON mc.movie_id = ka.movie_id
    WHERE 
        ka.production_year IS NOT NULL
        AND mch.actor_name <> a.name
)

SELECT 
    m.movie_title,
    COUNT(DISTINCT m.person_id) AS total_actors,
    STRING_AGG(m.actor_name, ', ') AS actor_names,
    AVG(mch.recursion_level) AS avg_recursion_level,
    MAX(mh.title) AS last_movie_title
FROM 
    movie_cast_hierarchy m
LEFT JOIN 
    aka_title mh ON m.movie_id = mh.movie_id
GROUP BY 
    m.movie_title
HAVING 
    COUNT(DISTINCT m.person_id) > 5
ORDER BY 
    total_actors DESC, 
    m.movie_title;

This SQL query performs several interesting and complex operations:

1. It uses a **recursive CTE** named `movie_cast_hierarchy` to build a hierarchy of movies and their casts, allowing for dynamically fetching related actors as long as they act in the same movie.

2. The base query of the CTE retrieves movies from the year 2000 and beyond, along with actors and their names.

3. The **UNION ALL** clause allows the recursion to continue, gathering additional layers of actors from other movies.

4. The **main SELECT statement** aggregates results from the CTE, providing insights into the number of actors per movie, their names, and calculating the average recursion level (indicating how many layers deep the actors are).

5. It uses **LEFT JOIN** to link the movie titles from the previously constructed CTE to allow fetching the last movie title dynamically.

6. Aggressive use of **string aggregation** with `STRING_AGG` to consolidate actor names into a single text string.

7. The query includes a **HAVING clause** to filter based on a condition involving the total number of actors.

8. Finally, the result is ordered by the total number of actors in descending order and by movie title.

This query showcases complex SQL capabilities that are integral for performance benchmarking in terms of complexity and execution strategies.
