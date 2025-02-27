WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id
), 

TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        aka_names,
        RANK() OVER (ORDER BY cast_count DESC) AS movie_rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    GROUP_CONCAT(DISTINCT ct.kind) AS company_types
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.movie_rank <= 10
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, tm.cast_count, tm.aka_names
ORDER BY 
    tm.cast_count DESC;
