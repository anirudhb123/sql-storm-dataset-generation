WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka.name, ', ') AS cast_names
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name aka ON aka.person_id = c.person_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count,
        cast_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    rm.cast_names
FROM 
    TopMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
