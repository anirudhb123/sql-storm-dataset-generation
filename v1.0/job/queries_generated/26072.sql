WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN
        title mt ON ak.movie_id = mt.id
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        aka_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    GROUP_CONCAT(DISTINCT ci.note) AS cast_notes,
    GROUP_CONCAT(DISTINCT pi.info) AS person_info
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON ci.movie_id = tm.movie_id
JOIN 
    person_info pi ON pi.person_id = ci.person_id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, tm.cast_count, tm.aka_names
ORDER BY 
    tm.cast_count DESC;
