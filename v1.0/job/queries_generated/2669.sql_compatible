
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank_in_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorMovieRoles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        c.role_id,
        COUNT(c.id) AS role_count,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    GROUP BY 
        a.name, t.title, c.role_id
),
CompanyMovieCount AS (
    SELECT 
        co.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        co.name
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 5
)
SELECT 
    r.movie_id,
    r.title AS movie_title,
    r.production_year,
    COALESCE(arm.actor_name, 'No Actors Found') AS actor_name,
    COALESCE(arm.role_count, 0) AS total_roles,
    cc.company_name,
    cc.total_movies
FROM 
    RankedMovies r
LEFT JOIN 
    ActorMovieRoles arm ON r.title = arm.movie_title
LEFT JOIN 
    CompanyMovieCount cc ON r.movie_id IN (SELECT mc.movie_id FROM movie_companies mc WHERE mc.company_id IN 
        (SELECT cn.id FROM company_name cn WHERE cn.country_code = 'USA'))
WHERE 
    r.rank_in_year <= 5
ORDER BY 
    r.production_year DESC, total_roles DESC
LIMIT 100;
