WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rnk
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL AND 
        a.title IS NOT NULL
),
CoActors AS (
    SELECT 
        ci1.movie_id,
        ak1.name AS actor_name,
        COUNT(DISTINCT ci2.person_id) AS co_actor_count
    FROM 
        cast_info ci1
    JOIN 
        cast_info ci2 ON ci1.movie_id = ci2.movie_id AND ci1.person_id <> ci2.person_id
    JOIN 
        aka_name ak1 ON ci1.person_id = ak1.person_id
    GROUP BY 
        ci1.movie_id, ak1.name
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ca.actor_name,
    ca.co_actor_count,
    mc.company_count,
    mc.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    CoActors ca ON rm.title = ca.actor_name
LEFT JOIN 
    MovieCompanies mc ON rm.production_year = mc.movie_id
WHERE 
    rm.rnk <= 10 AND 
    (mc.company_count IS NULL OR mc.company_count > 0)
ORDER BY 
    rm.production_year DESC, 
    ca.co_actor_count DESC;
