WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CharNameCounts AS (
    SELECT 
        cn.id AS char_id,
        cn.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        char_name cn
    LEFT JOIN 
        cast_info c ON cn.id = c.person_id
    GROUP BY 
        cn.id, cn.name
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cc.movie_count, 0) AS char_name_count,
    COALESCE(cm.company_count, 0) AS company_movie_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CharNameCounts cc ON rm.movie_id = cc.char_id
LEFT JOIN 
    CompanyMovieCounts cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rank <= 5
    AND (COALESCE(cc.movie_count, 0) > 0 OR COALESCE(cm.company_count, 0) > 0)
ORDER BY 
    rm.production_year DESC, rm.title ASC;
