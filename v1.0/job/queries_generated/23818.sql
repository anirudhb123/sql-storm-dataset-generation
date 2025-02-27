WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_movies
    FROM 
        RankedMovies
    WHERE 
        title_rank <= 5
),
PersonMovies AS (
    SELECT 
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
)
SELECT 
    tm.title AS Top_Title,
    tm.production_year,
    pm.actor_name,
    CASE 
        WHEN pm.actor_rank IS NULL THEN 'No Role Assigned'
        WHEN pm.actor_rank BETWEEN 1 AND 3 THEN 'Top Actor'
        ELSE 'Supporting Actor'
    END AS Role_Designation,
    COALESCE(NULLIF(pm.actor_name, ''), 'Unnamed Actor') AS Final_Actor_Name
FROM 
    TopMovies tm
LEFT JOIN 
    PersonMovies pm ON tm.movie_id = pm.movie_id
WHERE 
    tm.total_movies > 0
ORDER BY 
    tm.production_year DESC, 
    tm.title, 
    pm.actor_rank
UNION ALL
SELECT 
    'Unknown Title' AS Top_Title,
    NULL AS production_year,
    'Unknown Actor' AS actor_name,
    'Stunt Performer' AS Role_Designation,
    'Unnamed Actor' AS Final_Actor_Name
WHERE 
    NOT EXISTS (SELECT 1 FROM TopMovies)
LIMIT 100;
