WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(CASE WHEN ki.keyword IS NOT NULL THEN 1 ELSE 0 END) AS avg_keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_count,
    rm.avg_keywords
FROM 
    RankedMovies rm
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, rm.company_count DESC;
