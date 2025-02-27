WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mk.movie_id = mt.movie_id
    JOIN 
        keyword kc ON kc.id = mk.keyword_id
    JOIN 
        cast_info ci ON ci.movie_id = mt.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.title, mt.production_year
),
AvgCastCount AS (
    SELECT 
        AVG(cast_count) AS average_cast_count
    FROM 
        RankedMovies
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        aka_names,
        keywords,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        cast_count > (SELECT average_cast_count FROM AvgCastCount)
    ORDER BY 
        production_year DESC, cast_count DESC
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.aka_names,
    tm.keywords,
    tm.cast_count,
    CASE 
        WHEN tm.cast_count > 50 THEN 'Large Cast'
        WHEN tm.cast_count BETWEEN 20 AND 50 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    TopMovies tm
LIMIT 10;
