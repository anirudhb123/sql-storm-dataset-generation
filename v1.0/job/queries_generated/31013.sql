WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        ARRAY[mt.title] AS title_path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mh.level + 1,
        mh.title_path || mt.title
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    m.movie_title,
    CASE 
        WHEN m.level > 1 THEN 'Episode'
        ELSE 'Movie'
    END AS type,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY m.movie_id) AS total_actors,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info c ON c.movie_id = m.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
WHERE 
    m.movie_title ILIKE '%adventure%'
GROUP BY 
    a.name, m.movie_id, m.movie_title, m.level
ORDER BY 
    m.movie_id, total_actors DESC NULLS LAST;

-- Here’s a summary of what this query does:
-- 1. It defines a recursive CTE `movie_hierarchy` to get films and episodes in a hierarchical structure.
-- 2. It retrieves actors associated with each movie/episode, along with the movie title and type.
-- 3. Counts total distinct actors per movie, with a string concatenation of associated keywords, filtered by title containing "adventure".
-- 4. Finally, results are ordered by movie ID and the total number of actors, placing NULLs last.
