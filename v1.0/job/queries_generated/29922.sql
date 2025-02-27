WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL 
        AND t.title IS NOT NULL
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS num_movies
    FROM 
        movie_companies mc 
    JOIN 
        company_name c ON mc.company_id = c.id 
    JOIN 
        company_type ct ON mc.company_type_id = ct.id 
    GROUP BY 
        mc.movie_id, c.name, ct.kind
    HAVING 
        COUNT(*) > 1
),
ActorMovieRoles AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c 
    JOIN 
        aka_name ak ON c.person_id = ak.person_id 
    JOIN 
        role_type rt ON c.role_id = rt.id 
    GROUP BY 
        c.movie_id, ak.name, rt.role
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year,
    f.company_name,
    f.company_type,
    a.actor_name,
    a.role,
    a.role_count,
    rm.rank
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCompanies f ON rm.movie_id = f.movie_id 
LEFT JOIN 
    ActorMovieRoles a ON rm.movie_id = a.movie_id 
WHERE 
    rm.rank <= 10 
ORDER BY 
    rm.production_year DESC, 
    rm.rank, 
    a.role_count DESC, 
    f.num_movies DESC;
