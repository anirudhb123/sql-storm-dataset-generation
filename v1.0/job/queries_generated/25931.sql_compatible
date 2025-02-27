
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ARRAY_AGG(DISTINCT c.name) AS cast_names
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
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
        title,
        production_year,
        keyword_count,
        cast_names,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC, production_year ASC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.cast_names,
    pi.info AS person_info
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.keyword_count DESC, tm.production_year ASC;
