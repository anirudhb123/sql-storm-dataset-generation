WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    r.title,
    r.production_year,
    ac.actor_count,
    cd.company_name,
    cd.company_type,
    cd.company_count
FROM 
    RankedMovies r
LEFT JOIN 
    ActorCounts ac ON r.rank = 1 AND ac.movie_id = (SELECT MAX(movie_id) FROM complete_cast WHERE status_id IS NULL)
LEFT JOIN 
    CompanyDetails cd ON r.production_year = (SELECT MAX(production_year) FROM aka_title WHERE id = cd.movie_id)
WHERE 
    cd.company_count > 1
  AND 
    (r.production_year IS NOT NULL OR r.title IS NULL)
ORDER BY 
    r.production_year DESC,
    ac.actor_count DESC;
