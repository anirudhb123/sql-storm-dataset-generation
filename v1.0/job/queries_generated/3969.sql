WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT CASE WHEN r.role IS NOT NULL THEN r.role ELSE 'Unknown Role' END) AS roles
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieProduction AS (
    SELECT 
        mc.movie_id,
        string_agg(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title, 
    rm.production_year,
    rm.keyword,
    ar.actor_count,
    ar.roles,
    mp.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.id = ar.movie_id
LEFT JOIN 
    MovieProduction mp ON rm.id = mp.movie_id
WHERE 
    rm.rank <= 10 AND 
    (ar.actor_count IS NULL OR ar.actor_count > 5)
ORDER BY 
    rm.production_year DESC, 
    ar.actor_count DESC;
