
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year, 
        COUNT(DISTINCT kc.id) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS cast_names
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        keyword_count, 
        cast_count, 
        cast_names,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC, cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.keyword_count,
    tm.cast_count,
    tm.cast_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10;
