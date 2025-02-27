WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        aka_name ak ON mt.id = ak.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year > 2000  
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.aka_names,
        rm.cast_count,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count >= 5  
)

SELECT 
    tm.title,
    tm.production_year,
    tm.aka_names,
    tm.cast_count,
    ARRAY_AGG(DISTINCT p.name) AS cast_names
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    name p ON ci.person_id = p.id
WHERE 
    p.gender = 'F'  
GROUP BY 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.aka_names,
    tm.cast_count
ORDER BY 
    tm.cast_count DESC;