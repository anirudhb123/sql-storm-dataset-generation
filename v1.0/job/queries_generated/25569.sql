WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.cast_count
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;

This SQL query benchmarks string processing by performing multiple joins across various tables related to movie data and their keywords while aggregating the cast count per movie and selecting the top 5 movies per production year based on that count. It utilizes common table expressions (CTEs) for better readability and maintenance.
