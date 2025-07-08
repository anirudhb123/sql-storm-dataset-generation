
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count, 
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        COALESCE(COUNT(DISTINCT cn.name), 0) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    rm.cast_count, 
    mc.company_count, 
    rm.keywords
FROM 
    RankedMovies rm
JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.production_year >= 2000 
    AND mc.company_count > 1
ORDER BY 
    rm.cast_count DESC, 
    rm.production_year ASC
LIMIT 50;
