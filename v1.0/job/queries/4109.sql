WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        title m
    WHERE 
        m.production_year IS NOT NULL
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
ActorRoles AS (
    SELECT 
        ca.movie_id,
        ca.person_id,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ca
    JOIN 
        role_type r ON ca.role_id = r.id
    GROUP BY 
        ca.movie_id, ca.person_id, r.role
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        SUM(ar.role_count) AS total_roles
    FROM 
        aka_name a
    JOIN 
        ActorRoles ar ON a.person_id = ar.person_id
    GROUP BY 
        a.person_id, a.name
    ORDER BY 
        total_roles DESC
    LIMIT 10
)
SELECT 
    rm.title,
    rm.production_year,
    c.company_count,
    ta.name AS top_actor_name,
    ta.total_roles
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovieCounts c ON rm.movie_id = c.movie_id
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    TopActors ta ON ar.person_id = ta.person_id
WHERE 
    rm.rank <= 5 
    AND c.company_count > 1
ORDER BY 
    rm.production_year DESC, 
    rm.title;
