WITH RECURSIVE movie_hierarchy AS (
    -- Base case: select all movies that have no episodes (i.e., main titles)
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS depth
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL
    
    -- Recursive case: join movies with their episodes
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.depth + 1 AS depth
    FROM 
        title t
    JOIN 
        movie_hierarchy mh ON t.episode_of_id = mh.movie_id
)

-- Select relevant fields along with the number of episodes and average rating if applicable
SELECT 
    t.title AS movie_title,
    t.production_year,
    COALESCE(COUNT(e.id), 0) AS episode_count,
    ROUND(AVG(CASE WHEN r.rating IS NOT NULL THEN r.rating END), 2) AS average_rating,
    STRING_AGG(DISTINCT a.name, ', ') AS actors
FROM 
    movie_hierarchy mh
LEFT JOIN 
    title t ON mh.movie_id = t.id
LEFT JOIN 
    cast_info c ON t.id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    (SELECT movie_id, rating FROM movie_info WHERE info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')) r ON t.id = r.movie_id
LEFT JOIN 
    title e ON e.episode_of_id = t.id
GROUP BY 
    t.id
ORDER BY 
    t.production_year DESC, 
    episode_count DESC
LIMIT 10;

-- This query generates a list of movies with their associated episodes, actor names, 
-- and average ratings. It uses recursive CTEs to gather hierarchical movie data, 
-- including outer joins to track episodes and additional movie information.
