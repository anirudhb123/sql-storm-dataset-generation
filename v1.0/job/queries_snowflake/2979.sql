WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        a.title, a.production_year
),
TopYears AS (
    SELECT 
        production_year, 
        MAX(cast_count) AS max_cast_count
    FROM 
        RankedMovies
    GROUP BY 
        production_year
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.cast_count, 
    COALESCE(t.max_cast_count, 0) AS highest_cast_count
FROM 
    RankedMovies rm
LEFT JOIN 
    TopYears t ON rm.production_year = t.production_year
WHERE 
    rm.cast_count > (SELECT AVG(cast_count) FROM RankedMovies) 
    AND rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
