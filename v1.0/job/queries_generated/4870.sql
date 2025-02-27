WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id, 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_year <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(NULLIF(tm.cast_count, 0), 'No cast available') AS cast_status,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors_names
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count
HAVING 
    SUM(CASE WHEN ak.name IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    tm.production_year DESC, 
    tm.title;
