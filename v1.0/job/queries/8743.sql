WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keyword_count,
    rm.avg_roles
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.keyword_count DESC;
