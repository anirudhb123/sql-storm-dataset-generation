WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
    ORDER BY 
        actor_count DESC, company_count DESC
    LIMIT 10
)
SELECT 
    rm.title,
    rm.production_year,
    kt.kind,
    rm.actor_count,
    rm.company_count,
    rm.keyword_count
FROM 
    RankedMovies rm
JOIN 
    kind_type kt ON rm.kind_id = kt.id
WHERE 
    rm.actor_count > 5
ORDER BY 
    rm.production_year ASC;
