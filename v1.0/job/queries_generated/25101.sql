WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ak.name AS aka_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title m
    JOIN 
        aka_title ak ON ak.movie_id = m.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    GROUP BY 
        m.id, m.title, m.production_year, ak.name
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_name,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.aka_name,
    tm.cast_count,
    ARRAY_AGG(DISTINCT cn.name || ' (' || ct.kind || ')') AS companies,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = tm.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = tm.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.aka_name
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
