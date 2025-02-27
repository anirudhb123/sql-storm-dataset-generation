WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS movie_rank,
        COALESCE(m.info, 'No information') AS movie_info
    FROM 
        aka_title a
    LEFT JOIN 
        movie_info m ON a.id = m.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        r.role AS role_type,
        COUNT(c.movie_id) AS total_movies
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, a.name, r.role
    HAVING 
        COUNT(c.movie_id) > 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id, co.name
)
SELECT 
    rm.movie_title,
    rm.production_year,
    am.actor_name,
    am.role_type,
    mc.company_name,
    mc.company_count,
    rm.movie_info
FROM 
    RankedMovies rm
JOIN 
    ActorMovies am ON rm.movie_title = am.actor_name 
LEFT JOIN 
    MovieCompanies mc ON rm.movie_title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
WHERE 
    rm.movie_rank <= 10
  AND 
    (mc.company_count IS NULL OR mc.company_count > 1) 
ORDER BY 
    rm.production_year DESC, am.total_movies DESC
LIMIT 50;