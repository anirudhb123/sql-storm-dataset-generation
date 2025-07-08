
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
RecentProduction AS (
    SELECT 
        m.title,
        m.production_year,
        kv.keyword,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword kv ON mk.keyword_id = kv.id
    WHERE 
        m.production_year >= (SELECT MAX(production_year) FROM title) - 5
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(dp.total_cast, 0) AS total_cast,
    rp.keyword AS associated_keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    RecentProduction rp ON rm.title = rp.title AND rm.production_year = rp.production_year
LEFT JOIN 
    (SELECT 
         movie_id, COUNT(*) AS total_cast 
     FROM 
         complete_cast 
     GROUP BY 
         movie_id) dp ON rm.title = (SELECT title FROM aka_title WHERE id = dp.movie_id) 
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, total_cast DESC;
