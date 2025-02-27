WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn,
        COUNT(*) OVER () AS total_movies
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        ci.movie_id,
        ct.kind AS role
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
),
Directors AS (
    SELECT 
        DISTINCT mc.movie_id,
        cn.name AS company_name
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
),
CombinedInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.person_id,
        ar.name AS actor_name,
        ar.role,
        COALESCE(d.company_name, 'Unknown') AS director
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        Directors d ON rm.movie_id = d.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    STRING_AGG(DISTINCT actor_name || ' (' || role || ')', ', ') AS actors,
    director,
    total_movies,
    CASE 
        WHEN production_year = (SELECT MAX(production_year) FROM RankedMovies) THEN 'Latest Release'
        ELSE 'Older Release'
    END AS Release_Status
FROM 
    CombinedInfo
GROUP BY 
    movie_id, title, production_year, director, total_movies
ORDER BY 
    production_year DESC, title;
