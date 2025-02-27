
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        rm.keyword_count,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10  
)

SELECT 
    tm.production_year,
    STRING_AGG(DISTINCT tm.title, ', ') AS top_movie_titles,
    SUM(tm.cast_count) AS total_cast_count,
    SUM(tm.keyword_count) AS total_keyword_count
FROM 
    TopMovies tm
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;
