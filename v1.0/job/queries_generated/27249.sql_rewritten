WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        string_agg(DISTINCT a.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rnk
    FROM 
        aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND k.keyword IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rnk <= 5  
)
SELECT 
    movie_title,
    production_year,
    movie_keyword,
    cast_names,
    COUNT(*) OVER (PARTITION BY movie_keyword) AS keyword_frequency
FROM 
    TopMovies
ORDER BY 
    movie_keyword, production_year DESC;