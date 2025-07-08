
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast,
        COALESCE(SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END), 0) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.rank_by_cast,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast = 1
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(mi.info, 'No additional info') AS additional_info,
    CASE 
        WHEN tm.keyword_count > 10 THEN 'High Keyword Density'
        WHEN tm.keyword_count BETWEEN 1 AND 10 THEN 'Normal Keyword Density'
        ELSE 'No Keywords'
    END AS keyword_density,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM complete_cast cc WHERE cc.movie_id = t.id) THEN 'Incomplete Cast'
        ELSE 'Complete Cast'
    END AS cast_status
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON (tm.movie_title ILIKE '%' || mi.info || '%') AND tm.production_year = mi.movie_id
LEFT JOIN 
    title t ON tm.movie_title = t.title AND tm.production_year = t.production_year
ORDER BY 
    tm.production_year DESC, 
    tm.keyword_count DESC
LIMIT 10;
