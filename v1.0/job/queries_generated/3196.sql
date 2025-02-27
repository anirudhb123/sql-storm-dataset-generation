WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_by_year,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY at.movie_id) AS company_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role_type,
        COUNT(ci.movie_id) AS total_movies,
        SUM(CASE WHEN at.production_year >= 2000 THEN 1 ELSE 0 END) AS movies_since_2000
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        comp_cast_type ct ON rt.id = ct.id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name, ct.kind
)
SELECT 
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_type,
    ar.total_movies,
    ar.movies_since_2000,
    rm.company_count
FROM 
    RankedMovies rm
JOIN 
    ActorRoles ar ON ar.total_movies > 0
WHERE 
    rm.rank_by_year <= 5
ORDER BY 
    rm.production_year DESC, rm.title, ar.actor_name;
