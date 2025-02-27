WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CastDetails AS (
    SELECT 
        cm.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info cm
    JOIN 
        aka_name a ON cm.person_id = a.person_id
    JOIN 
        role_type r ON cm.role_id = r.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cd.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(cd.role_name, 'Unknown Role') AS role_name,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Contemporary'
        ELSE 'Recent'
    END AS movie_period
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
