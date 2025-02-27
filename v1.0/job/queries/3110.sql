WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.kind_id = 1
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.id) AS roles_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    am.actor_name,
    am.roles_count,
    mk.keywords,
    cm.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorMovies am ON rm.movie_id = am.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rn <= 10 AND 
    (am.roles_count IS NULL OR am.roles_count > 2)
ORDER BY 
    rm.production_year DESC, 
    rm.movie_id;
