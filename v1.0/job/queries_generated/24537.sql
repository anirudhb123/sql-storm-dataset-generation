WITH RecursiveActorMovies AS (
    -- CTE to find actors with their movies recursively
    SELECT 
        ca.person_id,
        at.movie_id,
        a.name AS actor_name,
        at.title AS movie_title,
        f.production_year
    FROM 
        cast_info ca
    JOIN aka_name a ON ca.person_id = a.person_id
    JOIN aka_title at ON ca.movie_id = at.movie_id
    JOIN title f ON at.movie_id = f.id
    WHERE 
        f.production_year >= 2000 
        AND a.name IS NOT NULL

    UNION ALL
    
    SELECT 
        ra.person_id,
        at.movie_id,
        a.name AS actor_name,
        at.title AS movie_title,
        f.production_year
    FROM 
        cast_info ra
    JOIN RecursiveActorMovies ram ON ra.movie_id = ram.movie_id
    JOIN aka_name a ON ra.person_id = a.person_id
    JOIN aka_title at ON ra.movie_id = at.movie_id
    JOIN title f ON at.movie_id = f.id
    WHERE 
        f.production_year < ram.production_year
)

SELECT 
    actor_name,
    movie_title,
    production_year,
    ROW_NUMBER() OVER (PARTITION BY actor_name ORDER BY production_year DESC) AS movie_rank,
    COUNT(*) OVER (PARTITION BY actor_name) AS total_movies,
    COALESCE(NULLIF(SUBSTR(movie_title, 1, 3), ''), 'No Title') AS adjusted_title
FROM 
    RecursiveActorMovies
WHERE 
    actor_name IS NOT NULL 
    AND movie_rank <= 5
ORDER BY 
    total_movies DESC, 
    actor_name;

-- Implementing a complex outer join with NULL logic 
SELECT 
    ca.person_id,
    a.name AS actor_name,
    mt.movie_id,
    mt.title AS movie_title,
    COALESCE(CAST(mi.info AS text), 'No Info Available') AS movie_info
FROM 
    cast_info ca
LEFT JOIN 
    aka_name a ON ca.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON ca.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
JOIN 
    aka_title at ON ca.movie_id = at.movie_id
JOIN 
    title mt ON at.movie_id = mt.id
WHERE 
    mt.production_year BETWEEN 2000 AND 2023
    AND (a.name IS NOT NULL OR mi.info IS NOT NULL)
ORDER BY 
    mt.production_year DESC, 
    a.name;

This SQL query consists of two parts. The first part utilizes a Common Table Expression (CTE) to recursively find actors with their movies from the year 2000 onwards, while applying various window functions for pagination and ranking. The second part demonstrates how to handle outer joins and NULL logic gracefully while fetching movie-related information alongside actors' names, ensuring that even if certain details are missing, informative alternatives are provided.
