WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000  -- Assuming we're interested in movies from 2000 onward
    
    UNION ALL
    
    SELECT 
        m.id AS title_id,
        m.title,
        m.production_year,
        m.episode_of_id,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.title_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS num_movies,
    AVG(t.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    MAX(t.production_year) AS latest_movie_year,
    SUM(CASE WHEN t.production_year IS NULL THEN 1 ELSE 0 END) AS null_year_count
FROM 
    cast_info c
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    MovieHierarchy t ON c.movie_id = t.title_id
WHERE 
    ak.name IS NOT NULL 
And ak.md5sum IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5  -- Only include actors in more than 5 movies
ORDER BY 
    num_movies DESC,
    latest_movie_year ASC
LIMIT 10;
