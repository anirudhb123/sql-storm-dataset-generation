WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(DISTINCT c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        year_rank,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        DISTINCT m.id AS movie_id,
        COALESCE(mi.info, 'No Info Available') AS movie_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    k.keyword_count,
    mi.movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywordCounts k ON tm.title = (SELECT title FROM aka_title WHERE id = tm.title)
LEFT JOIN 
    MovieInfo mi ON tm.title = (SELECT title FROM aka_title WHERE id = mi.movie_id)
WHERE 
    (tm.production_year % 2 = 0 OR k.keyword_count IS NULL) 
    AND (mi.movie_info IS NOT NULL OR tm.cast_count < 3)
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
