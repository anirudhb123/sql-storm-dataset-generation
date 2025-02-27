WITH MovieStats AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        keyword_count
    FROM 
        MovieStats
    WHERE 
        rank_per_year <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.keyword_count,
    COALESCE(mi.info, 'No Info Available') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.title = mi.info AND mi.note IS NULL 
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
