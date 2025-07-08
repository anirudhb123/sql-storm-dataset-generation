
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name) AS cast_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year BETWEEN 2000 AND 2020
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    LISTAGG(tm.cast_names, ', ') AS all_cast_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.cast_count DESC;
