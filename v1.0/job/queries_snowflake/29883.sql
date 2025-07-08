
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        movie_keyword,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.movie_keyword,
    tm.cast_count,
    LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names
FROM 
    TopMovies tm
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = tm.movie_id)
GROUP BY 
    tm.movie_title, tm.production_year, tm.movie_keyword, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
