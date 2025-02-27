WITH RECURSIVE MovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
        
    UNION ALL
    
    SELECT 
        m.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        cte.depth + 1
    FROM 
        MovieCTE cte
    JOIN 
        movie_link ml ON ml.movie_id = cte.movie_id
    JOIN 
        title t ON t.id = ml.linked_movie_id
    WHERE 
        cte.depth < 3  -- Limit the depth to avoid excessive recursion
)

SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY t.production_year DESC) AS movie_rank,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_keyword mk 
     WHERE 
        mk.movie_id = t.id AND mk.keyword_id IN (
            SELECT id FROM keyword WHERE keyword ILIKE '%action%'
        )
    ) AS action_keywords_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieCTE m ON ci.movie_id = m.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
JOIN 
    title t ON m.movie_id = t.id
WHERE 
    ak.name IS NOT NULL
    AND t.production_year IS NOT NULL
GROUP BY 
    ak.id, t.id
HAVING 
    COUNT(DISTINCT mc.company_id) > 1    -- Only include movies with more than one company
ORDER BY 
    actor_name, movie_rank;

This query performs the following operations:

1. Uses a recursive Common Table Expression (CTE) called `MovieCTE` to retrieve movies produced from the year 2000 onward and their linked movies, limiting the recursion depth to 3.
2. It retrieves actor names from `aka_name` and links them to their movies through `cast_info`.
3. It joins the results with the movie companies associated with the movies and the title information.
4. The query aggregates data to count distinct companies associated with each movie and ranks the movies by their production year for each actor.
5. A subquery counts the number of action-themed keywords associated with each movie.
6. Filters out actors and movies with NULL values and limits the results to those movies that have more than one associated production company.
7. The final result is ordered by the actor's name and the movie rank.
