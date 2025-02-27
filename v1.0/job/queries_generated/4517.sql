WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        m.id, m.title, m.production_year
), ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title t ON ci.movie_id = t.id
    GROUP BY 
        a.person_id, a.name
), CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(c.id) AS company_count,
        ARRAY_AGG(DISTINCT cn.name) AS companies
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
    ai.name AS actor_name,
    ai.movie_count,
    cs.company_count,
    cs.companies,
    CASE 
        WHEN rm.rn <= 3 THEN 'Top Movie in Year'
        ELSE 'Other Movie'
    END AS movie_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON rm.movie_id = ai.movie_count
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.rn <= 10
    AND ai.movie_count IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    movie_rank;
