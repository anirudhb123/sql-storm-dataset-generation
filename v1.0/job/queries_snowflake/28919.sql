
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        cast_names,
        ROW_NUMBER() OVER (PARTITION BY movie_keyword ORDER BY production_year DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    movie_title,
    production_year,
    movie_keyword,
    cast_names
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    movie_keyword, production_year DESC;
