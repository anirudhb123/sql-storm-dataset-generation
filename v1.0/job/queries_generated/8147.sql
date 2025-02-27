WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
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
    rm.actor_count,
    rm.actor_names,
    cs.company_count,
    cs.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
ORDER BY 
    rm.actor_count DESC, 
    cs.company_count DESC
LIMIT 10;
