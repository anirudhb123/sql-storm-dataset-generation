WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    COALESCE(avg_info.info, 'No info available') AS movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.production_year = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON tm.title = mi.info
LEFT JOIN 
    (SELECT 
        movie_id, 
        STRING_AGG(info, '; ') AS info 
    FROM 
        movie_info 
    GROUP BY 
        movie_id) avg_info ON tm.production_year = avg_info.movie_id
WHERE 
    tm.cast_count > 0
GROUP BY 
    tm.title, tm.production_year, avg_info.info
ORDER BY 
    tm.production_year DESC;
