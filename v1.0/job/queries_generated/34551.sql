WITH RECURSIVE movie_series AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        0 AS series_level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL -- start from top-level series

    UNION ALL

    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        ms.series_level + 1 AS series_level
    FROM 
        title t
    JOIN 
        movie_series ms ON t.episode_of_id = ms.title_id -- Recursive join to get episodes
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ms.series_level,
    COUNT(DISTINCT mi.info) AS movie_info_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS rn
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_series ms ON t.id = ms.title_id
WHERE 
    (t.production_year >= 2000 AND t.production_year < 2023) 
    OR (t.production_year IS NULL) -- allow for NULL production years
GROUP BY 
    a.name, t.title, t.production_year, ms.series_level
HAVING 
    COUNT(DISTINCT mi.info) > 0 -- only include movies with info
ORDER BY 
    actor_name, movie_title;
The query utilizes a recursive CTE to gather the series and episodes data, employs various joins to connect the actor details, movie titles, additional information about each movie (through `movie_info`), and the associated keywords. It also incorporates a window function to rank the movie titles for each actor by production year, along with NULL handling for production years. The final selection aggregates keywords and filters on the presence of movie information.
