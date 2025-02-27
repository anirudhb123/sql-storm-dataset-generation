WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ka.name, ', ') AS aka_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_title ka ON m.id = ka.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    tm.keyword_count,
    AVG(mi.info::FLOAT) AS average_info_length
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.aka_names, tm.keyword_count
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
