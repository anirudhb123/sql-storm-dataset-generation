
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT a.id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        m.id, m.title, m.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actors
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)

SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.actors,
    ARRAY_AGG(DISTINCT cmp.name) AS production_companies
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cmp ON mc.company_id = cmp.id
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, tm.actors
ORDER BY 
    tm.production_year, tm.movie_title;
