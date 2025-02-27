WITH RECURSIVE Filmography AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND ak.name IS NOT NULL
),
TopActors AS (
    SELECT 
        person_id,
        COUNT(*) AS total_movies,
        MAX(production_year) AS last_movie_year
    FROM 
        Filmography
    GROUP BY 
        person_id
    HAVING 
        COUNT(*) > 5 
        AND MAX(production_year) < (EXTRACT(YEAR FROM CURRENT_DATE) - 5)
)
SELECT 
    ak.actor_name,
    ta.total_movies,
    ta.last_movie_year,
    STRING_AGG(DISTINCT f.movie_title, ', ') AS movies,
    CASE 
        WHEN ta.total_movies IS NULL THEN 'No movies found'
        ELSE 'Active in film industry'
    END AS status,
    COUNT(*) FILTER (WHERE ak.name LIKE '%Smith%') AS smith_count
FROM 
    TopActors ta
JOIN 
    Filmography f ON ta.person_id = f.person_id
JOIN 
    aka_name ak ON f.person_id = ak.person_id
LEFT JOIN 
    title t ON f.movie_id = t.id
GROUP BY 
    ak.actor_name, ta.total_movies, ta.last_movie_year
ORDER BY 
    ta.total_movies DESC,
    ak.actor_name
LIMIT 10
OFFSET 0
UNION ALL
SELECT 
    'Unknown Actor' AS actor_name,
    COUNT(*) AS total_movies,
    NULL AS last_movie_year,
    STRING_AGG(DISTINCT t.title, ', ') AS movies,
    'Unknown' AS status,
    0 AS smith_count
FROM 
    aka_title t
WHERE 
    t.production_year IS NULL
GROUP BY 
    NULL
HAVING 
    COUNT(*) > 0;

