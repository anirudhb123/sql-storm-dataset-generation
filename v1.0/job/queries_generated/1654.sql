WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as year_rank
    FROM aka_title a
    WHERE a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        r.title, 
        r.production_year 
    FROM RankedMovies r 
    WHERE r.year_rank <= 5
),
ActorRoles AS (
    SELECT 
        ci.person_id, 
        ci.movie_id, 
        pt.role, 
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS actor_role_rank
    FROM cast_info ci
    JOIN role_type pt ON ci.role_id = pt.id
)
SELECT 
    an.name AS actor_name,
    tm.title AS movie_title,
    tm.production_year,
    COALESCE(ar.role, 'Unknown') AS role,
    COUNT(DISTINCT ar.movie_id) AS total_movies
FROM TopMovies tm
LEFT JOIN ActorRoles ar ON tm.movie_id = ar.movie_id
LEFT JOIN aka_name an ON ar.person_id = an.person_id
WHERE an.name IS NOT NULL
GROUP BY an.name, tm.title, tm.production_year, ar.role
HAVING COUNT(DISTINCT ar.movie_id) > 1
ORDER BY movie_title ASC, actor_name DESC;
